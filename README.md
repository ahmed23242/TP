# 🚨 Urban Incidents Reporter

A modern Flutter application for reporting and managing urban incidents in real-time.

## 📑 Table of Contents
- [Features](#-features)
- [Tech Stack](#️-tech-stack)
- [Project Structure](#-project-structure)
- [Detailed Documentation](#-detailed-documentation)
  - [Frontend](#frontend)
  - [Backend](#backend)
  - [Communication Flow](#communication-flow)
- [Package Details](#-package-details)
- [Getting Started](#-getting-started)
- [Supported Platforms](#-supported-platforms)
- [Security Features](#-security-features)
- [Contributing](#-contributing)
- [License](#-license)
- [Developer](#-developer)
- [Acknowledgments](#-acknowledgments)

## 🌟 Features

- 📱 Beautiful and intuitive user interface
- 🔐 Secure authentication with biometric support
- 📍 Real-time incident mapping
- 📸 Multiple media uploads (photos and videos) for incident documentation
- 🎤 Voice recording for detailed descriptions
- 🔄 Offline-first architecture
- 📊 Incident tracking and management
- 👥 Role-based access (Citizen/Admin)
- 🌐 Multi-language support
- 🌙 Dark/Light theme

## 🛠️ Tech Stack

- **Frontend**: Flutter
  - **State Management**: GetX
  - **Local Database**: SQLite
  - **Authentication**: JWT + Biometric
  - **Maps**: Google Maps Flutter
  - **Media**: Image Picker, Flutter Sound, Cached Network Image
  - **Location**: Geolocator
  - **Internationalization**: Flutter Intl

- **Backend**: Django
  - **Database**: PostgreSQL
  - **API**: Django REST Framework
  - **Authentication**: JWT
  - **Media Storage**: Django Storage
  - **Caching**: Redis
  - **Task Queue**: Celery

## 📁 Project Structure

The project is organized using a feature-based architecture:

```
accidentsapp/
├── lib/
│   ├── core/                 # Core functionality used across the app
│   │   ├── auth/             # Authentication services
│   │   ├── constants/        # App-wide constants
│   │   ├── database/         # Local database configuration
│   │   ├── network/          # Network services and API clients
│   │   ├── services/         # Common services
│   │   ├── theme/            # App theming
│   │   ├── utils/            # Utility functions
│   │   └── widgets/          # Reusable widgets
│   │
│   ├── features/             # App features
│   │   ├── auth/             # Authentication feature
│   │   │   ├── controllers/  # Controllers for auth screens
│   │   │   ├── models/       # Auth data models
│   │   │   ├── repositories/ # Auth data repositories
│   │   │   ├── screens/      # Auth UI screens
│   │   │   └── services/     # Auth-specific services
│   │   │
│   │   ├── home/             # Home feature
│   │   │   └── screens/      # Home screens
│   │   │
│   │   └── incidents/        # Incidents feature
│   │       ├── controllers/  # Incident controllers
│   │       ├── models/       # Incident data models
│   │       ├── repositories/ # Incident data repositories
│   │       ├── screens/      # Incident UI screens
│   │       ├── services/     # Incident-specific services
│   │       └── widgets/      # Incident-specific widgets
│   │
│   └── main.dart             # App entry point
│
├── backend/                  # Django backend
│   ├── admin_panel/          # Admin panel app
│   ├── docs/                 # API documentation
│   ├── incidents/            # Incidents app
│   ├── incidents_api/        # Incidents API
│   ├── templates/            # HTML templates
│   └── users/                # Users app
│
└── assets/                   # App assets
    ├── icons/                # App icons
    ├── images/               # App images
    └── flags/                # Language flags
```

## 📚 Detailed Documentation

### <a name="frontend"></a>Frontend

The frontend is built with Flutter, a cross-platform UI toolkit that allows us to build natively compiled applications from a single codebase.

#### Key Components

1. **State Management with GetX**
   - Reactive state management
   - Dependency injection
   - Route management
   - Example code:
   ```dart
   // Controller registration
   Get.put(AuthController());
   
   // State management
   final count = 0.obs;
   void increment() => count.value++;
   
   // Navigation
   Get.to(() => IncidentDetailsScreen(id: incidentId));
   ```

2. **Local Database with SQLite**
   - Used for offline-first architecture
   - Stores user data and incidents locally
   - Example code:
   ```dart
   // Database initialization
   final db = await openDatabase(
     join(await getDatabasesPath(), 'incidents_database.db'),
     onCreate: (db, version) {
       return db.execute(
         'CREATE TABLE incidents(id INTEGER PRIMARY KEY, title TEXT, description TEXT, latitude REAL, longitude REAL, status TEXT)',
       );
     },
     version: 1,
   );
   
   // Insert data
   await db.insert(
     'incidents',
     incident.toMap(),
     conflictAlgorithm: ConflictAlgorithm.replace,
   );
   ```

3. **Authentication System**
   - JWT token authentication
   - Biometric authentication
   - Secure storage for tokens
   - Example code:
   ```dart
   // JWT Authentication
   final response = await http.post(
     Uri.parse('$apiUrl/auth/login/'),
     headers: <String, String>{
       'Content-Type': 'application/json',
     },
     body: jsonEncode(<String, String>{
       'username': username,
       'password': password,
     }),
   );
   
   // Biometric Authentication
   final localAuth = LocalAuthentication();
   final didAuthenticate = await localAuth.authenticate(
     localizedReason: 'Please authenticate to access the app',
     options: const AuthenticationOptions(biometricOnly: true),
   );
   ```

4. **Maps Integration**
   - Google Maps for incident location
   - Geolocation services
   - Example code:
   ```dart
   GoogleMap(
     mapType: MapType.normal,
     initialCameraPosition: CameraPosition(
       target: LatLng(incident.latitude, incident.longitude),
       zoom: 14.0,
     ),
     markers: Set<Marker>.of(markers),
     onMapCreated: (GoogleMapController controller) {
       _controller.complete(controller);
     },
   )
   ```

5. **Multi-language Support**
   - Internationalization with Flutter Intl
   - Language switching capability
   - Example code:
   ```dart
   // Language switching
   void changeLanguage(String languageCode) {
     final locale = Locale(languageCode);
     Get.updateLocale(locale);
   }
   
   // Using translations
   Text(AppLocalizations.of(context).incidentReportTitle)
   ```

### <a name="backend"></a>Backend

The backend is built with Django, a high-level Python web framework that encourages rapid development and clean, pragmatic design.

#### Key Components

1. **Django REST Framework**
   - RESTful API design
   - Serialization
   - Authentication
   - Example code:
   ```python
   # Serializer
   class IncidentSerializer(serializers.ModelSerializer):
       class Meta:
           model = Incident
           fields = ['id', 'title', 'description', 'latitude', 'longitude', 
                     'created_at', 'updated_at', 'status', 'reporter']
   
   # ViewSet
   class IncidentViewSet(viewsets.ModelViewSet):
       queryset = Incident.objects.all()
       serializer_class = IncidentSerializer
       permission_classes = [IsAuthenticated]
       
       def get_queryset(self):
           user = self.request.user
           if user.is_staff:
               return Incident.objects.all()
           return Incident.objects.filter(reporter=user)
   ```

2. **JWT Authentication**
   - Token-based authentication
   - Refresh tokens
   - Example code:
   ```python
   # settings.py
   REST_FRAMEWORK = {
       'DEFAULT_AUTHENTICATION_CLASSES': (
           'rest_framework_simplejwt.authentication.JWTAuthentication',
       ),
   }
   
   SIMPLE_JWT = {
       'ACCESS_TOKEN_LIFETIME': timedelta(minutes=60),
       'REFRESH_TOKEN_LIFETIME': timedelta(days=14),
       'ROTATE_REFRESH_TOKENS': True,
   }
   ```

3. **PostgreSQL Database**
   - Relational database for data storage
   - Example model:
   ```python
   class Incident(models.Model):
       STATUS_CHOICES = (
           ('pending', 'Pending'),
           ('in_progress', 'In Progress'),
           ('resolved', 'Resolved'),
           ('closed', 'Closed'),
       )
       
       title = models.CharField(max_length=255)
       description = models.TextField()
       latitude = models.FloatField()
       longitude = models.FloatField()
       created_at = models.DateTimeField(auto_now_add=True)
       updated_at = models.DateTimeField(auto_now=True)
       status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
       reporter = models.ForeignKey(User, on_delete=models.CASCADE, related_name='incidents')
       
       def __str__(self):
           return self.title
   ```

4. **Media Storage**
   - File uploads handling
   - Example code:
   ```python
   class IncidentMedia(models.Model):
       incident = models.ForeignKey(Incident, on_delete=models.CASCADE, related_name='media')
       file = models.FileField(upload_to='incident_media/%Y/%m/%d/')
       file_type = models.CharField(max_length=10, choices=(
           ('image', 'Image'),
           ('video', 'Video'),
           ('audio', 'Audio'),
       ))
       uploaded_at = models.DateTimeField(auto_now_add=True)
   ```

5. **Celery for Asynchronous Tasks**
   - Background processing
   - Scheduled tasks
   - Example code:
   ```python
   # tasks.py
   @shared_task
   def process_incident_media(media_id):
       media = IncidentMedia.objects.get(id=media_id)
       # Process media (resize images, compress videos, etc.)
       # ...
       return f"Processed media {media_id}"
   
   # views.py
   def upload_media(request, incident_id):
       # ... handle file upload
       media = IncidentMedia.objects.create(incident_id=incident_id, file=file)
       process_incident_media.delay(media.id)
       return Response({'status': 'processing'})
   ```

### <a name="communication-flow"></a>Communication Flow

The frontend and backend communicate through RESTful API endpoints. Here's the typical flow:

1. **Authentication Flow**
   ```
   Flutter App                                Django Backend
       |                                           |
       |--- POST /api/auth/login/ --------------->|
       |                                           |
       |<-- 200 OK (access & refresh tokens) -----|
       |                                           |
       |--- GET /api/user/ (with token) --------->|
       |                                           |
       |<-- 200 OK (user data) ------------------|
   ```

2. **Incident Reporting Flow**
   ```
   Flutter App                                Django Backend
       |                                           |
       |--- POST /api/incidents/ ---------------->|
       |                                           |
       |<-- 201 Created (incident data) ----------|
       |                                           |
       |--- POST /api/incidents/{id}/media/ ----->|
       |                                           |
       |<-- 202 Accepted (processing) ------------|
       |                                           |
       |--- GET /api/incidents/{id}/ ------------>|
       |                                           |
       |<-- 200 OK (updated incident data) -------|
   ```

3. **Offline Synchronization Flow**
   ```
   Flutter App                                Django Backend
       |                                           |
       |--- POST /api/sync/ (batch updates) ----->|
       |                                           |
       |<-- 200 OK (sync results) ----------------|
   ```

## 📦 Package Details

### Frontend Packages

1. **GetX (^4.6.5)**
   - Purpose: State management, dependency injection, route management
   - [GitHub Repository](https://github.com/jonataslaw/getx)

2. **SQLite (^2.0.1)**
   - Purpose: Local database for offline storage
   - [pub.dev](https://pub.dev/packages/sqflite)

3. **Google Maps Flutter (^2.2.5)**
   - Purpose: Maps integration for incident location
   - [pub.dev](https://pub.dev/packages/google_maps_flutter)

4. **Image Picker (^0.8.7)**
   - Purpose: Selecting images from gallery or camera
   - [pub.dev](https://pub.dev/packages/image_picker)

5. **Flutter Sound (^9.2.13)**
   - Purpose: Audio recording for incident descriptions
   - [pub.dev](https://pub.dev/packages/flutter_sound)

6. **Geolocator (^9.0.2)**
   - Purpose: Getting device location
   - [pub.dev](https://pub.dev/packages/geolocator)

7. **Cached Network Image (^3.2.3)**
   - Purpose: Loading and caching network images
   - [pub.dev](https://pub.dev/packages/cached_network_image)

8. **Local Authentication (^2.1.6)**
   - Purpose: Biometric authentication
   - [pub.dev](https://pub.dev/packages/local_auth)

9. **Connectivity Plus (^3.0.3)**
   - Purpose: Network connectivity detection
   - [pub.dev](https://pub.dev/packages/connectivity_plus)

10. **Flutter Intl (^0.0.1)**
    - Purpose: Internationalization
    - [pub.dev](https://pub.dev/packages/flutter_intl)

### Backend Packages

1. **Django (4.2.0)**
   - Purpose: Web framework
   - [PyPI](https://pypi.org/project/Django/)

2. **Django REST Framework (3.14.0)**
   - Purpose: RESTful API framework
   - [PyPI](https://pypi.org/project/djangorestframework/)

3. **djangorestframework-simplejwt (5.2.2)**
   - Purpose: JWT authentication
   - [PyPI](https://pypi.org/project/djangorestframework-simplejwt/)

4. **psycopg2-binary (2.9.6)**
   - Purpose: PostgreSQL adapter
   - [PyPI](https://pypi.org/project/psycopg2-binary/)

5. **Pillow (9.5.0)**
   - Purpose: Image processing
   - [PyPI](https://pypi.org/project/Pillow/)

6. **django-storages (1.13.2)**
   - Purpose: Storage backends
   - [PyPI](https://pypi.org/project/django-storages/)

7. **celery (5.2.7)**
   - Purpose: Asynchronous task queue
   - [PyPI](https://pypi.org/project/celery/)

8. **redis (4.5.4)**
   - Purpose: Caching and message broker
   - [PyPI](https://pypi.org/project/redis/)

9. **django-cors-headers (3.14.0)**
   - Purpose: Cross-Origin Resource Sharing
   - [PyPI](https://pypi.org/project/django-cors-headers/)

10. **drf-yasg (1.21.5)**
    - Purpose: API documentation
    - [PyPI](https://pypi.org/project/drf-yasg/)

## 🚀 Getting Started

### Prerequisites

- Flutter SDK
- Android Studio / VS Code
- Python 3.8+ (for backend)
- Django 4.0+ (for backend)
- Git
- PostgreSQL
- Redis (for backend caching and Celery)

### Installation

1. Clone the repository

```bash
git clone https://github.com/AhmedBouha/accidentsapp.git
```

2. Install frontend dependencies

```bash
cd accidentsapp
flutter pub get
```

3. Install backend dependencies

```bash
cd backend
pip install -r requirements.txt
```

4. Set up PostgreSQL database

```bash
# Create database
createdb incidents_db

# Configure database in backend/settings.py
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'incidents_db',
        'USER': 'postgres',
        'PASSWORD': 'your_password',
        'HOST': 'localhost',
        'PORT': '5432',
    }
}
```

5. Run migrations

```bash
python manage.py migrate
```

6. Create a superuser

```bash
python manage.py createsuperuser
```

7. Start the backend server

```bash
python manage.py runserver
```

8. Start Celery worker (in a separate terminal)

```bash
celery -A backend worker -l info
```

9. Run the Flutter app

```bash
cd ..
flutter run
```

## 📱 Supported Platforms

- Android
- iOS
- Web (experimental)

## 🔒 Security Features

- Biometric authentication
- JWT token-based security
- Secure local storage
- Encrypted data transmission
- HTTPS enforcement
- CSRF protection
- XSS prevention
- Rate limiting

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👨‍💻 Developer

**Ahmed Abd Dayme AhmedBouha**

- GitHub: [github](https://github.com/AhmedBouha)
- Email: ahmedabddayme@gmail.com
- Website: [My Portfolio](https://ahmedabddayme.vercel.app)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Django community for the robust backend framework
- All contributors and supporters
- The open-source community

---

Made with ❤️ by Ahmed Abd Dayme AhmedBouha
