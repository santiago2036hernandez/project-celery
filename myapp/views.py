# myapp/views.py
from django.shortcuts import render, redirect
from django.http import HttpResponse
from .tasks import repeat_task_every_ten_seconds, send_welcome_email
from myapp.tasks import repeat_task_every_five_seconds

def register(request):
    # ... Código para procesar el registro del usuario ...
    
    # Después de registrar al usuario, llama a la tarea Celery para enviar el correo de bienvenida
    send_welcome_email.delay(user.email)
    
    return redirect('registration_success')



def start_repeat_task(request):
    repeat_task_every_five_seconds.apply_async((), countdown=5)
    return HttpResponse("Tarea programada iniciada!!!")

def hello(request):
    return HttpResponse("Tarea programada iniciada")  

def start_repeat_task2(request):
    repeat_task_every_ten_seconds.apply_async((), countdown=5)
    return HttpResponse("Tarea programada iniciada noww!!!")