# Ambiente local com Docker Compose

Este ambiente é apenas para desenvolvimento local. O Compose cria containers para PostgreSQL, RabbitMQ e Keycloak usando imagens com versões fixadas no ADR-005. As portas publicadas escutam somente em `127.0.0.1`.

## Preparar e iniciar

1. Inicie o Docker Desktop.
2. Copie `.env.example` para `.env` e substitua cada senha por um valor local único. O arquivo `.env` é ignorado pelo Git.
3. No arquivo de hosts do Windows (`C:\Windows\System32\drivers\etc\hosts`), adicione como administrador. Esta máquina pode solicitar credenciais administrativas:

   ```text
   127.0.0.1 keycloak.flowbridge.test
   ```

4. Na raiz do repositório, valide e inicie:

   ```powershell
   docker compose config --quiet
   docker compose up --detach --wait
   docker compose ps
   ```

O serviço do Keycloak usa esse mesmo nome como alias na rede Compose. Assim o host — navegador e API executada localmente — acessa `http://keycloak.flowbridge.test:8080`, e o hostname publicado no discovery OIDC não muda para um nome interno de container.

## Verificações

```powershell
docker compose --profile verification run --rm postgres-grants-check
Invoke-RestMethod http://keycloak.flowbridge.test:8080/realms/flowbridge/.well-known/openid-configuration
```

O primeiro comando verifica que o usuário `flowbridge_migrator` pode criar objetos no banco/schema, enquanto `flowbridge_api` e `flowbridge_worker` podem conectar e usar o schema, mas não criar tabelas. Não há tabelas de aplicação ainda; permissões nelas serão definidas junto com as migrations.

O discovery inicial confirma apenas que o realm `flowbridge` existe e publica o issuer canônico. O arquivo `infra/keycloak/flowbridge-realm.json` cria somente esse realm vazio: clientes, usuários, scopes e roles ficam para a fase de identidade. Sem a entrada no `hosts`, ainda é possível conferir o issuer via `http://127.0.0.1:8080/realms/flowbridge/.well-known/openid-configuration`, mas aplicações locais não resolverão o hostname canônico.

## Portas e persistência

| Serviço | Endereço local | Volume persistente |
|---|---|---|
| PostgreSQL | `127.0.0.1:5432` | `postgres_data` em `/var/lib/postgresql` |
| RabbitMQ AMQP | `127.0.0.1:5672` | `rabbitmq_data` |
| RabbitMQ management | `http://127.0.0.1:15672` | `rabbitmq_data` |
| Keycloak | `http://keycloak.flowbridge.test:8080` | `keycloak_data` |

Volumes nomeados preservam os dados quando os containers reiniciam ou quando se executa `docker compose down`. `docker compose down -v` remove os volumes e apaga os dados locais; não use esse comando como rotina.

O usuário `flowbridge_bootstrap` é superuser apenas para inicializar roles. As credenciais de migration e runtime são distintas. O Keycloak roda em modo de desenvolvimento com HTTP e realm mínimo; nada disso representa configuração de produção.
