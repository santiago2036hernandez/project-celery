up:
	docker compose build && docker compose up && statics


collectstatic:
	docker compose exec backend python3 manage.py collectstatic

down:
	docker compose down

admin:
	docker compose exec backend python3 manage.py createsuperuser

statics:
	docker compose exec backend python3 manage.py collectstatic --noinput

cities:
	docker compose exec backend python3 manage.py cities_light

setup: migrate cities admin

merge:
	docker compose exec backend python3 manage.py makemigrations --merge

mm: migrations migrate

sm:
	docker compose exec backend python3 manage.py showmigrations

app:
	docker compose exec backend python3 manage.py startapp $(name) && mv $(name) apps/$(name)

build_push:
	aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(registry)
	docker build -t abclick .
	docker tag abclick:latest $(registry)/abclick:latest
	docker push $(registry)/abclick:latest

build_and_deploy_image:
	docker build -t ${ECR_REGISTRY}/${ECR_NAME}${ENVIRONMENT_SUFFIX}:$(ECR_TAG) -f dockerfile .
	@echo "Project image built!"

	docker push ${ECR_REGISTRY}/${ECR_NAME}${ENVIRONMENT_SUFFIX}:$(ECR_TAG)
	@echo "Project image pushed!"

build_and_deploy_nginx_image:
	cd nginx && \
	docker build -t ${ECR_REGISTRY}/${ECR_NAME}${ENVIRONMENT_SUFFIX}:$(ECR_TAG) -f dockerfile .
	@echo "Project image built!"

	docker push ${ECR_REGISTRY}/${ECR_NAME}${ENVIRONMENT_SUFFIX}:$(ECR_TAG)
	@echo "Project image pushed!"

##Updates to check###################
build_and_deploy_celery_worker_image:
	docker build -t ${ECR_REGISTRY}/${ECR_NAME}${ENVIRONMENT_SUFFIX}:$(ECR_TAG) -f dockerfile.celery_worker .
	@echo "Project image built!"

	docker push ${ECR_REGISTRY}/${ECR_NAME}${ENVIRONMENT_SUFFIX}:$(ECR_TAG)
	@echo "Project image pushed!"

build_and_deploy_celery_beat_image:
	docker build -t ${ECR_REGISTRY}/${ECR_NAME}${ENVIRONMENT_SUFFIX}:$(ECR_TAG) -f dockerfile.celery_beat .
	@echo "Project image built!"

	docker push ${ECR_REGISTRY}/${ECR_NAME}${ENVIRONMENT_SUFFIX}:$(ECR_TAG)
	@echo "Project image pushed!"

