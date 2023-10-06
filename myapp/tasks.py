# myapp/tasks.py
from celery import shared_task
from django.core.mail import send_mail
import time
@shared_task
def send_welcome_email(email):
    subject = 'Bienvenido a nuestro sitio'
    message = 'Gracias por registrarte en nuestro sitio. Esperamos que disfrutes tu experiencia.'
    from_email = 'info@example.com'
    recipient_list = [email]
    send_mail(subject, message, from_email, recipient_list)


@shared_task
def repeat_task_every_five_seconds():
    while True:
        print("Tarea ejecutada")
        time.sleep(5)

@shared_task
def repeat_task_every_ten_seconds():
    while True:
        print("Tarea ejecutada con exito!!")
        time.sleep(5)