# myproject/celery.py
from __future__ import absolute_import, unicode_literals
import os
from celery import Celery

# Configura la aplicación Django para que Celery la utilice
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myproject.settings')

app = Celery('myproject')

# Configuración de Celery
app.config_from_object('django.conf:settings', namespace='CELERY')

# Carga las tareas de todas las aplicaciones de Django
app.autodiscover_tasks()

@app.task(bind=True)
def debug_task(self):
    print('Request: {0!r}'.format(self.request))
