from django.contrib import messages
from django.contrib.auth.decorators import login_required, user_passes_test
from django.shortcuts import get_object_or_404, render, redirect
from django.conf import settings
from incidents.models import Incident
from django.db.models import Count
from django.utils import timezone
from datetime import timedelta

# Créer un formulaire intégré puisque le fichier forms.py pourrait ne pas être accessible
from django import forms

class IncidentForm(forms.ModelForm):
    class Meta:
        model = Incident
        fields = ['title', 'description', 'incident_type', 'status', 'latitude', 'longitude', 'photo', 'voice_note', 'sync_status']
        widgets = {
            'description': forms.Textarea(attrs={'rows': 4, 'class': 'form-control'}),
            'title': forms.TextInput(attrs={'class': 'form-control'}),
            'incident_type': forms.Select(attrs={'class': 'form-select'}),
            'status': forms.Select(attrs={'class': 'form-select'}),
            'sync_status': forms.Select(attrs={'class': 'form-select'}),
            'latitude': forms.NumberInput(attrs={'step': '0.000001', 'class': 'form-control'}),
            'longitude': forms.NumberInput(attrs={'step': '0.000001', 'class': 'form-control'}),
            'photo': forms.ClearableFileInput(attrs={'class': 'form-control'}),
            'voice_note': forms.ClearableFileInput(attrs={'class': 'form-control'}),
        }
    
    clear_photo = forms.BooleanField(required=False, widget=forms.HiddenInput())
    clear_audio = forms.BooleanField(required=False, widget=forms.HiddenInput())
    
    def save(self, commit=True):
        instance = super().save(commit=False)
        
        if self.cleaned_data.get('clear_photo'):
            instance.photo.delete()
            instance.photo = None
        
        if self.cleaned_data.get('clear_audio'):
            instance.voice_note.delete()
            instance.voice_note = None
        
        if commit:
            instance.save()
        
        return instance

# Remplacer staff_member_required par une fonction personnalisée
def is_staff(user):
    return user.is_authenticated and user.is_staff

@login_required
@user_passes_test(is_staff)
def admin_dashboard(request):
    """Vue du tableau de bord d'administration"""
    # Statistiques générales
    total_incidents = Incident.objects.count()
    
    # Incidents récents (7 derniers jours)
    week_ago = timezone.now() - timedelta(days=7)
    recent_incidents = Incident.objects.filter(created_at__gte=week_ago).count()
    
    # Statistiques par statut
    status_stats_raw = Incident.objects.values('status').annotate(count=Count('status'))
    status_stats = []
    for stat in status_stats_raw:
        percentage = 0
        if total_incidents > 0:
            percentage = int((stat['count'] * 100) / total_incidents)
        
        status_name = stat['status']
        for status_choice in Incident.STATUS_CHOICES:
            if status_choice[0] == status_name:
                status_name = status_choice[1]
                break
                
        status_stats.append({
            'status': stat['status'],
            'status_name': status_name,
            'count': stat['count'],
            'percentage': percentage
        })
    
    # Statistiques par type d'incident
    type_stats_raw = Incident.objects.values('incident_type').annotate(count=Count('incident_type'))
    type_stats = []
    for stat in type_stats_raw:
        percentage = 0
        if total_incidents > 0:
            percentage = int((stat['count'] * 100) / total_incidents)
            
        type_name = stat['incident_type']
        for type_choice in Incident.INCIDENT_TYPES:
            if type_choice[0] == type_name:
                type_name = type_choice[1]
                break
                
        type_stats.append({
            'incident_type': stat['incident_type'],
            'type_name': type_name,
            'count': stat['count'],
            'percentage': percentage
        })
    
    # Incidents récents (les 5 derniers)
    latest_incidents = Incident.objects.all().order_by('-created_at')[:5]
    
    context = {
        'page_title': 'Tableau de bord',
        'total_incidents': total_incidents,
        'recent_incidents': recent_incidents,
        'status_stats': status_stats,
        'type_stats': type_stats,
        'latest_incidents': latest_incidents,
        'incident_types': dict(Incident.INCIDENT_TYPES),
        'status_choices': dict(Incident.STATUS_CHOICES),
        'google_maps_api_key': getattr(settings, 'GOOGLE_MAPS_API_KEY', ''),
    }
    
    return render(request, 'admin/dashboard.html', context)

@login_required
@user_passes_test(is_staff)
def admin_incidents_list(request):
    incidents = Incident.objects.all().order_by('-created_at')
    
    # Filtres
    status_filter = request.GET.get('status', '')
    type_filter = request.GET.get('type', '')
    search_query = request.GET.get('q', '')
    
    if status_filter:
        incidents = incidents.filter(status=status_filter)
    if type_filter:
        incidents = incidents.filter(incident_type=type_filter)
    if search_query:
        incidents = incidents.filter(title__icontains=search_query) | incidents.filter(description__icontains=search_query)
    
    return render(request, 'admin/incidents_list.html', {
        'page_title': 'Liste des incidents',
        'incidents': incidents,
        'status_filter': status_filter,
        'type_filter': type_filter,
        'search_query': search_query,
        'incident_types': dict(Incident.INCIDENT_TYPES),
        'status_choices': dict(Incident.STATUS_CHOICES),
    })

@login_required
@user_passes_test(is_staff)
def admin_incident_create(request):
    """Vue pour créer un nouvel incident"""
    if request.method == 'POST':
        form = IncidentForm(request.POST, request.FILES)
        if form.is_valid():
            # Créer un nouvel incident mais ne pas sauvegarder immédiatement
            incident = form.save(commit=False)
            
            # Définir l'utilisateur et la date de création
            incident.user = request.user  # L'administrateur qui crée l'incident
            incident.created_at = timezone.now()
            
            # Sauvegarder l'incident
            incident.save()
            
            messages.success(request, f"L'incident #{incident.id} a été créé avec succès.")
            return redirect('admin_incident_detail', incident_id=incident.id)
    else:
        form = IncidentForm(initial={
            'status': 'pending',
            'sync_status': 'synced',
        })
    
    return render(request, 'admin/incident_create.html', {
        'page_title': 'Créer un nouvel incident',
        'form': form,
        'google_maps_api_key': getattr(settings, 'GOOGLE_MAPS_API_KEY', '')
    })

@login_required
@user_passes_test(is_staff)
def admin_incident_detail(request, incident_id):
    incident = get_object_or_404(Incident, id=incident_id)
    return render(request, 'admin/incident_detail.html', {
        'page_title': f'Incident #{incident.id}',
        'incident': incident,
        'google_maps_api_key': getattr(settings, 'GOOGLE_MAPS_API_KEY', '')
    })

@login_required
@user_passes_test(is_staff)
def admin_incident_edit(request, incident_id):
    incident = get_object_or_404(Incident, id=incident_id)
    
    if request.method == 'POST':
        form = IncidentForm(request.POST, request.FILES, instance=incident)
        if form.is_valid():
            form.save()
            messages.success(request, f"L'incident #{incident.id} a été mis à jour avec succès.")
            return redirect('admin_incident_detail', incident_id=incident.id)
    else:
        form = IncidentForm(instance=incident)
    
    return render(request, 'admin/incident_edit.html', {
        'page_title': f'Éditer incident #{incident.id}',
        'form': form,
        'incident': incident,
        'is_create': False,
        'google_maps_api_key': getattr(settings, 'GOOGLE_MAPS_API_KEY', '')
    }) 