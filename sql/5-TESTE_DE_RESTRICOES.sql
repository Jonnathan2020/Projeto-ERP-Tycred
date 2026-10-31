USE TYCRED;

-- ======================================================================
-- BATERIA DE TESTES DE RESTRIÇÕES (CONSTRAINTS E CHAVES)
-- O objetivo de todos os INSERTS abaixo é GERAR UM ERRO.
-- ======================================================================

SELECT '--- 1. TESTANDO RESTRIÇÃO CHECK NA TABELA PESSOA (SEXO) ---' AS Mensagem;
-- Erro esperado: Conflito com a restrição CHECK (SEXO IN ('M','F','O')).
INSERT INTO PESSOA (ID_PESSOA, CPF, NOME, SOBRENOME, SEXO, ESTADO_CIVIL, DATA_NASC)
VALUES (99, '99992999999', 'Teste', 'Erro', 'X', 'SOLTEIRO', '2000-01-01');

SELECT '--- 2. TESTANDO RESTRIÇÃO CHECK NA TABELA PESSOA (ESTADO_CIVIL) ---' AS Mensagem;
-- Erro esperado: Conflito com a restrição CHECK do Estado Civil.
INSERT INTO PESSOA (ID_PESSOA, CPF, NOME, SOBRENOME, SEXO, ESTADO_CIVIL, DATA_NASC)
VALUES (100, '88188888888', 'Teste', 'Erro', 'M', 'COMPLICADO', '2000-01-01');

SELECT '--- 3. TESTANDO RESTRIÇÃO UNIQUE (CPF DUPLICADO) ---' AS Mensagem;
-- Pré-requisito: Inserimos uma pessoa válida primeiro.
INSERT INTO PESSOA (ID_PESSOA, CPF, NOME, SOBRENOME, SEXO, ESTADO_CIVIL, DATA_NASC)
VALUES (101, '77777777777', 'Valido', 'Um', 'M', 'SOLTEIRO', '2000-01-01');
-- Erro esperado: Violação da restrição UNIQUE KEY (O CPF já existe no banco).
INSERT INTO PESSOA (ID_PESSOA, CPF, NOME, SOBRENOME, SEXO, ESTADO_CIVIL, DATA_NASC)
VALUES (102, '77777777777', 'Invalido', 'Dois', 'F', 'SOLTEIRA', '2000-01-01');

SELECT '--- 4. TESTANDO INTEGRIDADE REFERENCIAL (FK) EM USUARIO ---' AS Mensagem;
-- Erro esperado: Conflito de FOREIGN KEY. O ID_PESSOA 999 não existe na tabela PESSOA.
INSERT INTO USUARIO (ID_PESSOA, LOGIN, SENHA_HASH, TIPO_USUARIO, STATUS_ACESSO)
VALUES (999, 'teste.erro', 'hash', 'CLIENTE', 'ATIVO');

SELECT '--- 5. TESTANDO RESTRIÇÃO UNIQUE 1:1 EM USUARIO ---' AS Mensagem;
-- Pré-requisito: A Pessoa 101 válida já está no banco. Vamos criar um usuário para ela.
INSERT INTO USUARIO (ID_PESSOA, LOGIN, SENHA_HASH, TIPO_USUARIO, STATUS_ACESSO)
VALUES (101, 'teste.ok', 'hash', 'CLIENTE', 'ATIVO');
-- Erro esperado: Violação de UNIQUE KEY no ID_PESSOA. Uma pessoa não pode ter 2 usuários.
INSERT INTO USUARIO (ID_PESSOA, LOGIN, SENHA_HASH, TIPO_USUARIO, STATUS_ACESSO)
VALUES (101, 'teste.duplicado', 'hash', 'FUNCIONARIO', 'ATIVO');

SELECT '--- 6. TESTANDO RESTRIÇÃO CHECK (TIPO_USUARIO) ---' AS Mensagem;
-- Erro esperado: Conflito com a restrição CHECK (TIPO_USUARIO IN('CLIENTE', 'FUNCIONARIO', 'SISTEMA')).
-- Inserindo Pessoa válida para teste
INSERT INTO PESSOA (ID_PESSOA, CPF, NOME, SOBRENOME, SEXO, ESTADO_CIVIL, DATA_NASC)
VALUES (103, '66666666666', 'Outro', 'Teste', 'M', 'SOLTEIRO', '2000-01-01');
-- O erro ocorre aqui (ADMINISTRADOR não é válido no CHECK de Usuario):
INSERT INTO USUARIO (ID_PESSOA, LOGIN, SENHA_HASH, TIPO_USUARIO, STATUS_ACESSO)
VALUES (103, 'login.admin', 'hash', 'ADMINISTRADOR', 'ATIVO');

SELECT '--- 7. TESTANDO VALOR NULO (NOT NULL) EM CLIENTE ---' AS Mensagem;
-- Erro esperado: Não é possível inserir o valor NULL na coluna 'ID_PESSOA', pois a tabela exige dados.
INSERT INTO CLIENTE (ID_CLIENTE, CNPJ, ID_PESSOA, PROFISSAO, RENDA_DECLARADA)
VALUES (99, NULL, NULL, 'TESTE', 1000.00);

SELECT '--- 8. TESTANDO CHAVE ESTRANGEIRA (FK) EM EMPRESTIMO ---' AS Mensagem;
-- Erro esperado: Conflito de FOREIGN KEY. A FAIXA_JUROS 999 não existe.
-- Pré-requisito: Cliente válido e Empresa válida inseridos
INSERT INTO EMPRESA (ID_EMPRESA, RAZAO_SOCIAL) VALUES (99, 'EMPRESA TESTE');
INSERT INTO CLIENTE (ID_CLIENTE, ID_PESSOA) VALUES (99, 103);
-- O erro ocorre aqui:
INSERT INTO EMPRESTIMO (ID_EMPRESTIMO, ID_CLIENTE, ID_EMPRESA, ID_FAIXA_JUROS, ID_TAXA_JUROS, STATUS_EMPRESTIMO)
VALUES (99, 99, 99, 999, 1, 1);

SELECT '--- 9. TESTANDO ESTOURO DE TIPO DE DADO (VARCHAR/DECIMAL) ---' AS Mensagem;
-- Erro esperado: Os dados de cadeia de caracteres seriam truncados ou gerariam erro (O campo BANCO só aceita 3 caracteres).
INSERT INTO CONTA_BANCARIA (ID_PESSOA, BANCO, AGENCIA, CONTA)
VALUES (103, '0001', '1234', '12345-6');

-- Limpeza da sujeira gerada pelos testes (apaga apenas os que deram certo para não poluir o banco)
DELETE FROM USUARIO WHERE ID_PESSOA = 101;
DELETE FROM CLIENTE WHERE ID_CLIENTE = 99;
DELETE FROM EMPRESA WHERE ID_EMPRESA = 99;
DELETE FROM PESSOA WHERE ID_PESSOA IN (101, 103);