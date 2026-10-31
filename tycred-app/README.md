# TyCred ERP (HTML + JavaScript + MySQL)

## Como rodar
1. Instale o Node.js 18+ (https://nodejs.org).
2. Nesta pasta, rode:  `npm install`
3. Abra o arquivo `.env` desta pasta, troque `DB_PASSWORD` pela senha do seu MySQL e inicie:  `npm start`

4. Abra http://localhost:3000

O `.env` aceita DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME e PORT. Não compartilhe nem versione esse arquivo (o `.gitignore` já o ignora).

## O que a plataforma faz
- Dashboard com KPIs e gráficos (filtro Hoje / Esse mês / 30 dias / Tudo / Personalizar).
- Listagem, busca, cadastro, edição e exclusão de todas as tabelas do banco.
- Formulários gerados a partir da estrutura do banco (FKs viram listas, CHECK ... IN (...) vira lista de opções).
- Tabelas com PK simples recebem o próximo ID automaticamente.
- Campos LONGBLOB e SENHA_HASH não são exibidos.
