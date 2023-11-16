setup:
	@bash hack/setup.sh
clone:
	@bash hack/clone.sh
up: clone
	docker compose up --build -d
stop:
	docker compose down
