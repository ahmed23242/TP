from django.contrib import messages
from django.contrib.auth.decorators import login_required, staff_member_required
from django.shortcuts import get_object_or_404, render, redirect
from django.conf import settings
from django.http import HttpResponseRedirect
from django.urls import reverse
from django.core.paginator import Paginator
from django.db.models import Count
from incidents.models import Incident
from users.models import User
from backend.forms import IncidentForm

@login_required
@staff_member_required
def admin_incidents_list(request):
    incidents = Incident.objects.all().order_by('-created_at')
    
    # Compteurs pour le tableau de bord
    total_count = incidents.count()
    pending_count = incidents.filter(status='pending').count()
    in_progress_count = incidents.filter(status='in_progress').count()
    resolved_count = incidents.filter(status='resolved').count()
    
    # Données pour les graphiques
    import json
    from django.utils.safestring import mark_safe
    
    # Données pour le graphique par statut
    status_data = {
        'labels': ['En attente', 'En cours', 'Résolus', 'Rejetés'],
        'counts': [
            pending_count,
            in_progress_count,
            resolved_count,
            incidents.filter(status='rejected').count()
        ],
        'colors': [
            'rgba(255, 152, 0, 0.7)',   # En attente (warning)
            'rgba(63, 81, 181, 0.7)',    # En cours (info)
            'rgba(0, 200, 150, 0.7)',    # Résolu (success)
            'rgba(244, 67, 54, 0.7)'     # Rejeté (danger)
        ]
    }
    
    # Données pour le graphique par type
    type_labels = []
    type_counts = []
    for type_key, type_name in Incident.INCIDENT_TYPES:
        count = incidents.filter(incident_type=type_key).count()
        if count > 0:  # Ne montrer que les types avec des incidents
            type_labels.append(type_name)
            type_counts.append(count)
    
    type_data = {
        'labels': type_labels,
        'counts': type_counts,
        'colors': [
            'rgba(244, 67, 54, 0.7)',    # Accident (danger)
            'rgba(255, 152, 0, 0.7)',    # Incendie (warning)
            'rgba(63, 81, 181, 0.7)',    # Médical (info)
            'rgba(45, 55, 72, 0.7)',     # Crime (dark)
            'rgba(158, 158, 158, 0.7)'   # Autre (secondary)
        ]
    }
    
    # Conversion en JSON
    status_chart_data = mark_safe(json.dumps(status_data))
    type_chart_data = mark_safe(json.dumps(type_data))
    
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
        'total_count': total_count,
        'pending_count': pending_count,
        'in_progress_count': in_progress_count,
        'resolved_count': resolved_count,
        'status_chart_data': status_chart_data,
        'type_chart_data': type_chart_data,
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
        # Only update the status field
        original_data = {
            'title': incident.title,
            'description': incident.description,
            'incident_type': incident.incident_type,
            'latitude': incident.latitude,
            'longitude': incident.longitude,
            'sync_status': incident.sync_status,
            'user': incident.user,
            # Keep all other fields unchanged
        }
        
        # Create a copy of POST data that we can modify
        post_data = request.POST.copy()
        
        # Apply the original values for all fields except status
        for field, value in original_data.items():
            if field in post_data and field != 'status':
                post_data[field] = value
        
        form = IncidentForm(post_data, instance=incident)
        
        if form.is_valid():
            # Only save the status field
            incident.status = form.cleaned_data['status']
            incident.save(update_fields=['status'])
            
            messages.success(request, f"Le statut de l'incident #{incident.id} a été mis à jour avec succès.")
            return redirect('admin_incident_detail', incident_id=incident.id)
    else:
        form = IncidentForm(instance=incident)
    
    return render(request, 'admin/incident_edit.html', {
        'form': form,
        'incident': incident,
        'is_create': False,  # Ensure template knows this is an edit view
        'google_maps_api_key': settings.GOOGLE_MAPS_API_KEY
    }) 

@login_required
@staff_member_required
def admin_incident_update_status(request, incident_id):
    """
    View to update incident status directly from the incidents list
    """
    if request.method == 'POST':
        incident = get_object_or_404(Incident, id=incident_id)
        new_status = request.POST.get('status')
        
        # Validate that the status is one of the allowed choices
        valid_statuses = [status[0] for status in Incident.STATUS_CHOICES]
        
        if new_status in valid_statuses:
            # Only update the status field
            incident.status = new_status
            incident.save(update_fields=['status'])
            messages.success(request, f"Le statut de l'incident #{incident.id} a été mis à jour avec succès.")
        else:
            messages.error(request, "Statut invalide.")
    
    # Redirect back to the incidents list, preserving any filters
    referer = request.META.get('HTTP_REFERER')
    if referer:
        return HttpResponseRedirect(referer)
    return redirect('admin_incidents_list')

@login_required
@staff_member_required
def admin_users_list(request):
    users = User.objects.all().order_by('-date_joined')
    
    # Add incident count to each user
    users = users.annotate(incident_count=Count('incident'))
    
    # Filters
    role_filter = request.GET.get('role', '')
    search_query = request.GET.get('search', '')
    
    if role_filter:
        users = users.filter(role=role_filter)
    if search_query:
        users = users.filter(username__icontains=search_query) | \
               users.filter(email__icontains=search_query) | \
               users.filter(phone__icontains=search_query)
    
    # Pagination
    paginator = Paginator(users, 20)  # 20 users per page
    page_number = request.GET.get('page', 1)
    users_page = paginator.get_page(page_number)
    
    return render(request, 'admin/users_list.html', {
        'users': users_page,
        'role_filter': role_filter,
        'search_query': search_query,
    })

@login_required
@staff_member_required
def admin_user_delete(request, user_id):
    user = get_object_or_404(User, id=user_id)
    
    if request.method == 'POST':
        # Delete all incidents associated with this user
        Incident.objects.filter(user=user).delete()
        
        # Delete the user
        username = user.username
        user.delete()
        
        messages.success(request, f"L'utilisateur {username} et tous ses incidents ont été supprimés.")
        return redirect('admin_users_list')
    
    return redirect('admin_users_list')