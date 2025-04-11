from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from drf_yasg.views import get_schema_view
from drf_yasg import openapi
from rest_framework import permissions
from incidents_api.views.admin_views import (
    admin_incident_detail, 
    admin_incident_edit, 
    admin_incidents_list, 
    admin_dashboard,
    admin_incident_create
)

schema_view = get_schema_view(
    openapi.Info(
        title="Urban Incidents API",
        default_version='v1',
        description="API for reporting and managing urban incidents",
    ),
    public=True,
    permission_classes=(permissions.AllowAny,),
)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/users/', include('users.urls')),
    path('api/incidents/', include('incidents.urls')),
    path('swagger/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
    path('redoc/', schema_view.with_ui('redoc', cache_timeout=0), name='schema-redoc'),
    
    # URLs du panneau d'administration personnalisé
    path('', admin_dashboard, name='admin_dashboard'),  # Page d'accueil = tableau de bord
    path('admin-panel/', admin_dashboard, name='admin_dashboard_alt'),  # URL alternative
    path('admin-panel/incidents/', admin_incidents_list, name='admin_incidents_list'),
    path('admin-panel/incidents/create/', admin_incident_create, name='admin_incident_create'),
    path('admin-panel/incidents/<int:incident_id>/', admin_incident_detail, name='admin_incident_detail'),
    path('admin-panel/incidents/<int:incident_id>/edit/', admin_incident_edit, name='admin_incident_edit'),
    
    # URLs d'authentification Django
    path('accounts/', include('django.contrib.auth.urls')),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
