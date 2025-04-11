from django.contrib import messages
from django.contrib.auth.decorators import login_required, staff_member_required
from django.shortcuts import get_object_or_404, render, redirect
from django.conf import settings
from incidents.models import Incident
from backend.forms import IncidentForm

@login_required
@staff_member_required
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
        'incidents': incidents,
        'status_filter': status_filter,
        'type_filter': type_filter,
        'search_query': search_query,
        'incident_types': dict(Incident.INCIDENT_TYPES),
        'status_choices': dict(Incident.STATUS_CHOICES),
    })

@login_required
@staff_member_required
def admin_incident_detail(request, incident_id):
    incident = get_object_or_404(Incident, id=incident_id)
    return render(request, 'admin/incident_detail.html', {
        'incident': incident,
        'google_maps_api_key': settings.GOOGLE_MAPS_API_KEY
    })

@login_required
@staff_member_required
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
        'form': form,
        'incident': incident,
        'google_maps_api_key': settings.GOOGLE_MAPS_API_KEY
    })

@login_required
@staff_member_required
def admin_incident_create(request):
    if request.method == 'POST':
        form = IncidentForm(request.POST, request.FILES)
        if form.is_valid():
            incident = form.save(commit=False)
            # Si l'utilisateur est connecté, associer l'incident à cet utilisateur
            if request.user.is_authenticated:
                incident.user = request.user
            incident.save()
            messages.success(request, "L'incident a été créé avec succès.")
            return redirect('admin_incident_detail', incident_id=incident.id)
    else:
        form = IncidentForm(initial={
            'status': 'pending',
            'sync_status': 'synced',
        })
    
    return render(request, 'admin/incident_create.html', {
        'form': form,
    }) 