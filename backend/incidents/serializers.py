from rest_framework import serializers
from .models import Incident
from django.contrib.auth import get_user_model

User = get_user_model()

class IncidentSerializer(serializers.ModelSerializer):
    user = serializers.PrimaryKeyRelatedField(read_only=True)
    photo_url = serializers.SerializerMethodField()
    voice_note_url = serializers.SerializerMethodField()

    class Meta:
        model = Incident
        fields = (
            'id', 'title', 'description', 'incident_type', 'photo', 'photo_url',
            'voice_note', 'voice_note_url', 'latitude', 'longitude', 'status',
            'created_at', 'updated_at', 'user'
        )
        read_only_fields = ('id', 'created_at', 'updated_at', 'status')

    def get_photo_url(self, obj):
        if obj.photo:
            return self.context['request'].build_absolute_uri(obj.photo.url)
        return None

    def get_voice_note_url(self, obj):
        if obj.voice_note:
            return self.context['request'].build_absolute_uri(obj.voice_note.url)
        return None

    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)
