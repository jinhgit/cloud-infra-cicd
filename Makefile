# 로컬 품질 게이트 (AWS 유료 리소스 생성 없음)
.PHONY: help check test fmt validate integration build-images free clean

help:
	@echo "make check          - fmt + validate + BE test (기본 게이트)"
	@echo "make test           - BE unit tests"
	@echo "make fmt            - terraform fmt -check"
	@echo "make validate       - terraform validate"
	@echo "make integration    - docker compose curl 통합 테스트"
	@echo "make build-images   - linux/amd64 이미지 빌드 (푸시 없음)"
	@echo "make free           - ./scripts/dev-free.sh"
	@echo "make clean          - compose down"

check: fmt validate test
	@echo ""
	@echo "OK: make check 통과 (과금 apply 없음)"

test:
	cd BE && npm test

fmt:
	cd terraform && terraform fmt -check -recursive -diff

validate:
	cd terraform && terraform init -backend=false -input=false >/dev/null
	cd terraform && terraform validate

integration:
	chmod +x scripts/integration-test.sh
	./scripts/integration-test.sh

build-images:
	chmod +x scripts/build-images.sh
	./scripts/build-images.sh

free:
	chmod +x scripts/dev-free.sh
	./scripts/dev-free.sh

clean:
	docker compose down -v --remove-orphans || true
