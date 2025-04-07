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
            # Conserver le created_at tel qu'il a été défini côté mobile
            created_at = incident_data.get('created_at')
            
            # Vérifier si l'incident existe déjà (en cas de resync)
            existing_incident = None
            if 'id' in incident_data and Incident.objects.filter(id=incident_data['id']).exists():
                # Mettre à jour l'incident existant
                existing_incident = Incident.objects.get(id=incident_data['id'])
                serializer = self.get_serializer(existing_incident, data=incident_data, partial=True)
            else:
                # Créer un nouvel incident
                serializer = self.get_serializer(data=incident_data)
                
            if serializer.is_valid():
                # Enregistrer les chemins locaux du mobile si fournis
                photo_path = incident_data.get('photo_path')
                voice_note_path = incident_data.get('voice_note_path')
                
                # Enregistrer l'incident avec tous les champs nécessaires
                saved_incident = serializer.save(
                    user=request.user, 
                    sync_status='synced',
                    photo_path=photo_path,
                    voice_note_path=voice_note_path
                )
                
                # Si l'incident a été synchronisé avec succès, renvoyer les données mises à jour
                results.append({
                    'success': True,
                    'data': self.get_serializer(saved_incident).data,
                    'message': 'Incident synchronisé avec succès'
                })
            else:
                results.append({
                    'success': False,
                    'errors': serializer.errors,
                    'message': 'Erreur lors de la synchronisation'
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
