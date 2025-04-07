from django.shortcuts import render
from rest_framework import viewsets, permissions, filters, status
from rest_framework.response import Response
from rest_framework.decorators import action
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from django_filters.rest_framework import DjangoFilterBackend
from .models import Incident
from .serializers import IncidentSerializer, UserSerializer
from django.contrib.auth import get_user_model

User = get_user_model()

# Create your views here.

class IsOwnerOrAdmin(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        return request.user.is_staff or obj.user == request.user

class IncidentViewSet(viewsets.ModelViewSet):
    serializer_class = IncidentSerializer
    parser_classes = (MultiPartParser, FormParser, JSONParser)
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrAdmin]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'incident_type', 'sync_status']
    search_fields = ['title', 'description']
    ordering_fields = ['created_at', 'updated_at', 'status']
    ordering = ['-created_at']

    def get_queryset(self):
        if self.request.user.role == 'admin':
            return Incident.objects.all()
        return Incident.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
        
    @action(detail=False, methods=['post'], url_path='sync')
    def sync_incidents(self, request):
        """
        Synchronise les incidents en attente depuis l'application mobile.
        """
        incidents_data = request.data
        
        if not isinstance(incidents_data, list):
            incidents_data = [incidents_data]
            
        results = []
        for incident_data in incidents_data:
            # Vérifier si l'incident existe déjà (en cas de resync)
            if 'id' in incident_data and Incident.objects.filter(id=incident_data['id']).exists():
                # Mettre à jour l'incident existant
                incident = Incident.objects.get(id=incident_data['id'])
                serializer = self.get_serializer(incident, data=incident_data, partial=True)
            else:
                # Créer un nouvel incident
                serializer = self.get_serializer(data=incident_data)
                
            if serializer.is_valid():
                serializer.save(user=request.user, sync_status='synced')
                results.append({
                    'success': True,
                    'data': serializer.data
                })
            else:
                results.append({
                    'success': False,
                    'errors': serializer.errors
                })
                
        return Response(results, status=status.HTTP_200_OK)
        
class UserViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        # Les admins peuvent voir tous les utilisateurs
        if self.request.user.role == 'admin':
            return User.objects.all()
        # Les utilisateurs normaux ne peuvent voir que leur propre profil
        return User.objects.filter(id=self.request.user.id)
