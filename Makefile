COMPOSE_FILE = srcs/docker-compose.yml
LOGIN = mjusta
DATA_DIR = /home/$(LOGIN)/data

all: up

up:
	sudo mkdir -p $(DATA_DIR)/mariadb
	sudo mkdir -p $(DATA_DIR)/wordpress
	docker compose -f $(COMPOSE_FILE) up --build -d

down:
	docker compose -f $(COMPOSE_FILE) down

stop:
	docker compose -f $(COMPOSE_FILE) stop

start:
	docker compose -f $(COMPOSE_FILE) start

restart: down up

logs:
	docker compose -f $(COMPOSE_FILE) logs -f

ps:
	docker compose -f $(COMPOSE_FILE) ps

clean:
	docker compose -f $(COMPOSE_FILE) down --volumes --remove-orphans

fclean:
	docker compose -f $(COMPOSE_FILE) down --rmi all --volumes --remove-orphans
	docker system prune -af
	sudo rm -rf $(DATA_DIR)/mariadb
	sudo rm -rf $(DATA_DIR)/wordpress

re: fclean all

.PHONY: all up down stop start restart logs ps clean fclean re