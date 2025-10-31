from django.contrib import admin
from auditoria.models import AuditMark


@admin.register(AuditMark)
class AuditMarkAdmin(admin.ModelAdmin):
    list_display = ['symbol', 'description_short', 'work_paper_number',
                   'category', 'audit', 'is_active', 'created_at']
    list_filter = ['is_active', 'category', 'audit']
    search_fields = ['description', 'work_paper_number', 'symbol', 'audit__title']
    readonly_fields = ['created_at', 'updated_at']

    fieldsets = (
        ('Información Básica', {
            'fields': ('audit', 'symbol', 'description')
        }),
        ('Emparejamiento y Categorización', {
            'fields': ('work_paper_number', 'category')
        }),
        ('Estado', {
            'fields': ('is_active',)
        }),
        ('Metadatos', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

    def description_short(self, obj):
        """Mostrar descripción truncada en la lista"""
        if len(obj.description) > 50:
            return obj.description[:50] + '...'
        return obj.description
    description_short.short_description = 'Descripción'