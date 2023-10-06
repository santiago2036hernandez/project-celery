# myapp/urls.py
from django.urls import path
from . import views

urlpatterns = [
    # ... Otras URL de la aplicación ...
    path('start_repeat_task/', views.start_repeat_task, name='start_repeat_task'),
    path('start_repeat_task2/', views.start_repeat_task2, name='start_repeat_task2'),
    path('hello/', views.hello, name='hello'),
]
