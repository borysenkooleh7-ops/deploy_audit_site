"""
Vistas para el sistema de marcas de auditoría
"""

from django.contrib.auth.decorators import login_required
from django.shortcuts import get_object_or_404
from django.http import JsonResponse, HttpResponse
from audits.models import Audit
from auditoria.services.audit_mark_import_service import AuditMarkImportService
from auditoria.services.audit_mark_template_generator import AuditMarkTemplateGenerator
import logging

logger = logging.getLogger(__name__)


def _user_has_audit_access(user, audit):
    """Verificar si el usuario puede acceder a esta auditoría"""
    if hasattr(user, 'role') and user.role and user.role.name == 'audit_manager':
        return audit.audit_manager == user
    else:
        return audit.assigned_users.filter(id=user.id).exists()


@login_required
def upload_audit_marks(request, audit_id):
    """
    Manejar carga de Excel de marca de auditoría.

    POST /auditoria/audit/<audit_id>/upload-marks/

    Esperado:
        - request.FILES['excel_file']: Archivo Excel
        - request.POST.get('replace_existing'): 'on' o None

    Devuelve:
        Respuesta JSON con estadísticas de importación
    """
    audit = get_object_or_404(Audit, id=audit_id)

    # Verificar que el usuario tenga acceso
    if not _user_has_audit_access(request.user, audit):
        return JsonResponse({'error': 'Acceso denegado'}, status=403)

    if request.method != 'POST':
        return JsonResponse({'error': 'Método no permitido'}, status=405)

    if 'excel_file' not in request.FILES:
        return JsonResponse({'error': 'No se cargó ningún archivo'}, status=400)

    try:
        excel_file = request.FILES['excel_file']
        replace_existing = request.POST.get('replace_existing') == 'on'

        # Importar marcas
        service = AuditMarkImportService(audit_id, excel_file)
        result = service.import_marks(replace_existing=replace_existing)

        return JsonResponse(result)

    except Exception as e:
        logger.exception(f"Error al importar marcas de auditoría: {e}")
        return JsonResponse({'error': str(e)}, status=500)


@login_required
def download_audit_mark_template(request):
    """
    Generar y descargar plantilla Excel.

    GET /auditoria/audit-mark-template/download/

    Devuelve:
        Archivo Excel para descarga
    """
    generator = AuditMarkTemplateGenerator()
    return generator.get_http_response(filename="plantilla_marcas_auditoria.xlsx")
