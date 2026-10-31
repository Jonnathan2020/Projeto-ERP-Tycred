-- =====================================================================
-- TYCRED · ETAPAS 18, 19 e 20
-- Consultas gerenciais (G), de auditoria (A) e apoio à decisão
-- Compatível com MySQL 8.0+ (usa CTE e funções de janela)
-- Execute o arquivo inteiro na MESMA sessão (os parâmetros abaixo são variáveis de sessão).
-- Os status são sempre resolvidos pelo NOME (join nas tabelas STATUS_*), nunca pelo ID.
-- =====================================================================
USE TYCRED;

-- ---------------------------------------------------------------------
-- PARÂMETROS DE NEGÓCIO (ajuste conforme a política da empresa)
-- ---------------------------------------------------------------------
SET @validade_score_dias      = 30;  -- RO007 M2: validade do score na decisão de crédito
SET @prazo_conciliacao_dias   = 5;   -- dias aceitáveis entre pagamento e conciliação
SET @meses_inatividade        = 12;  -- RGN001 M4: inativação automática após 12 meses
SET @dias_fila_parada         = 3;   -- empréstimo parado em análise/financeiro além deste prazo

-- =====================================================================
-- Formato: PERGUNTA DO NEGÓCIO + SQL + INFORMAÇÃO PARA DECISÃO
-- =====================================================================

-- G01 · Qual é o funil de crédito? Quantos empréstimos e quanto dinheiro estão em cada etapa?
SELECT se.NOME_STATUS                                   AS STATUS_EMPRESTIMO,
       COUNT(*)                                         AS QTD_EMPRESTIMOS,
       SUM(e.VALOR_SOLICITADO)                          AS VALOR_SOLICITADO,
       SUM(IFNULL(e.VALOR_APROVADO,0))                  AS VALOR_APROVADO,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS PERC_DO_TOTAL
FROM EMPRESTIMO e
JOIN STATUS_EMPRESTIMO se ON se.ID_STATUS_EMPRESTIMO = e.STATUS_EMPRESTIMO
GROUP BY se.NOME_STATUS
ORDER BY QTD_EMPRESTIMOS DESC;

-- G02 · A taxa de aprovação de crédito está subindo ou caindo mês a mês?
SELECT DATE_FORMAT(e.DATA_DECISAO,'%Y-%m')                  AS MES_DECISAO,
       COUNT(*)                                             AS DECISOES,
       SUM(se.NOME_STATUS <> 'REPROVADO')                   AS APROVADOS,
       SUM(se.NOME_STATUS = 'REPROVADO')                    AS REPROVADOS,
       ROUND(100 * SUM(se.NOME_STATUS <> 'REPROVADO') / COUNT(*), 1) AS TAXA_APROVACAO_PERC
FROM EMPRESTIMO e
JOIN STATUS_EMPRESTIMO se ON se.ID_STATUS_EMPRESTIMO = e.STATUS_EMPRESTIMO
WHERE e.DATA_DECISAO IS NOT NULL
  AND se.NOME_STATUS NOT IN ('PROPOSTA','EM ANALISE','CANCELADO')
GROUP BY DATE_FORMAT(e.DATA_DECISAO,'%Y-%m')
ORDER BY MES_DECISAO;

-- G03 · Por que reprovamos propostas? Quais são os motivos mais frequentes?
SELECT IFNULL(NULLIF(TRIM(e.MOTIVO_REPROVACAO),''),'(motivo não informado)') AS MOTIVO,
       COUNT(*)                         AS QTD_REPROVACOES,
       SUM(e.VALOR_SOLICITADO)          AS VALOR_NAO_CONCEDIDO,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS PERC_DAS_REPROVACOES
FROM EMPRESTIMO e
JOIN STATUS_EMPRESTIMO se ON se.ID_STATUS_EMPRESTIMO = e.STATUS_EMPRESTIMO
WHERE se.NOME_STATUS = 'REPROVADO'
GROUP BY MOTIVO
ORDER BY QTD_REPROVACOES DESC;

-- G04 · Quanto dinheiro saiu (desembolso) por mês, com qual ticket e prazo médios?
SELECT DATE_FORMAT(e.DATA_DESEMBOLSO,'%Y-%m') AS MES_DESEMBOLSO,
       COUNT(*)                               AS QTD_EMPRESTIMOS,
       SUM(e.VALOR_APROVADO)                  AS VALOR_DESEMBOLSADO,
       ROUND(AVG(e.VALOR_APROVADO),2)         AS TICKET_MEDIO,
       ROUND(AVG(e.QTD_PARCELAS),1)           AS PRAZO_MEDIO_PARCELAS,
       SUM(IFNULL(e.VALOR_COMISSAO,0))        AS COMISSOES_GERADAS
FROM EMPRESTIMO e
WHERE e.DATA_DESEMBOLSO IS NOT NULL
GROUP BY DATE_FORMAT(e.DATA_DESEMBOLSO,'%Y-%m')
ORDER BY MES_DESEMBOLSO;

-- G05 · Quanto temos a receber e qual parte já está em atraso?
-- G05-A · Carteira por status da parcela
SELECT sp.NOME_STATUS_PARCELA AS STATUS_PARCELA,
       COUNT(*)               AS QTD_PARCELAS,
       SUM(p.VALOR_INICIAL + p.VALOR_JUROS + p.VALOR_MULTA - p.VALOR_DESCONTO) AS VALOR_TOTAL,
       ROUND(100 * SUM(p.VALOR_INICIAL + p.VALOR_JUROS + p.VALOR_MULTA - p.VALOR_DESCONTO)
             / SUM(SUM(p.VALOR_INICIAL + p.VALOR_JUROS + p.VALOR_MULTA - p.VALOR_DESCONTO)) OVER (), 1) AS PERC_DO_VALOR
FROM PARCELA p
JOIN STATUS_PARCELA sp ON sp.ID_STATUS_PARCELA = p.STATUS_PARCELA
GROUP BY sp.NOME_STATUS_PARCELA
ORDER BY VALOR_TOTAL DESC;

-- G05-B · Índice de inadimplência (valor em atraso ÷ valor em aberto)
SELECT SUM(v.VALOR_TOTAL)                                                      AS CARTEIRA_EM_ABERTO,
       SUM(CASE WHEN v.ST = 'EM ATRASO' THEN v.VALOR_TOTAL ELSE 0 END)         AS VALOR_EM_ATRASO,
       ROUND(100 * SUM(CASE WHEN v.ST = 'EM ATRASO' THEN v.VALOR_TOTAL ELSE 0 END)
             / NULLIF(SUM(v.VALOR_TOTAL),0), 2)                                AS INDICE_INADIMPLENCIA_PERC
FROM (SELECT sp.NOME_STATUS_PARCELA AS ST,
             p.VALOR_INICIAL + p.VALOR_JUROS + p.VALOR_MULTA - p.VALOR_DESCONTO AS VALOR_TOTAL
      FROM PARCELA p
      JOIN STATUS_PARCELA sp ON sp.ID_STATUS_PARCELA = p.STATUS_PARCELA
      WHERE sp.NOME_STATUS_PARCELA IN ('A PAGAR','EM ATRASO','PARCIALMENTE PAGA')) v;

-- G06 · Há quanto tempo as parcelas estão atrasadas? (aging da inadimplência)
SELECT CASE WHEN x.DIAS_ATRASO BETWEEN 1  AND 30 THEN '1) 1 a 30 dias'
            WHEN x.DIAS_ATRASO BETWEEN 31 AND 60 THEN '2) 31 a 60 dias'
            WHEN x.DIAS_ATRASO BETWEEN 61 AND 90 THEN '3) 61 a 90 dias'
            ELSE '4) Mais de 90 dias' END AS FAIXA_DE_ATRASO,
       COUNT(*)                  AS QTD_PARCELAS,
       COUNT(DISTINCT x.ID_CLIENTE) AS QTD_CLIENTES,
       SUM(x.VALOR_TOTAL)        AS VALOR_EM_ATRASO
FROM (SELECT p.ID_PARCELA, p.ID_CLIENTE,
             GREATEST(DATEDIFF(CURDATE(), DATE(p.DATA_VENCIMENTO)),0) AS DIAS_ATRASO,
             p.VALOR_INICIAL + p.VALOR_JUROS + p.VALOR_MULTA - p.VALOR_DESCONTO AS VALOR_TOTAL
      FROM PARCELA p
      JOIN STATUS_PARCELA sp ON sp.ID_STATUS_PARCELA = p.STATUS_PARCELA
      WHERE sp.NOME_STATUS_PARCELA = 'EM ATRASO') x
GROUP BY FAIXA_DE_ATRASO
ORDER BY FAIXA_DE_ATRASO;

-- G07 · Quem devemos cobrar primeiro? (RO008 M4: maior valor em atraso e maior tempo de atraso)
SELECT c.ID_CLIENTE,
       CONCAT(pe.NOME,' ',pe.SOBRENOME)                              AS CLIENTE,
       COUNT(*)                                                      AS PARCELAS_EM_ATRASO,
       SUM(p.VALOR_INICIAL + p.VALOR_JUROS + p.VALOR_MULTA - p.VALOR_DESCONTO) AS VALOR_EM_ATRASO,
       MAX(DATEDIFF(CURDATE(), DATE(p.DATA_VENCIMENTO)))             AS MAIOR_ATRASO_DIAS,
       (SELECT COUNT(*)
          FROM ACORDO a
          JOIN STATUS_ACORDO sa ON sa.ID_STATUS_ACORDO = a.STATUS_ACORDO
          JOIN EMPRESTIMO ea    ON ea.ID_EMPRESTIMO   = a.ID_EMPRESTIMO
         WHERE ea.ID_CLIENTE = c.ID_CLIENTE
           AND sa.NOME_STATUS_ACORDO = 'DESCUMPRIDO')                AS ACORDOS_DESCUMPRIDOS
FROM PARCELA p
JOIN STATUS_PARCELA sp ON sp.ID_STATUS_PARCELA = p.STATUS_PARCELA
JOIN CLIENTE c         ON c.ID_CLIENTE = p.ID_CLIENTE
JOIN PESSOA pe         ON pe.ID_PESSOA = c.ID_PESSOA
WHERE sp.NOME_STATUS_PARCELA = 'EM ATRASO'
GROUP BY c.ID_CLIENTE, pe.NOME, pe.SOBRENOME
ORDER BY VALOR_EM_ATRASO DESC, MAIOR_ATRASO_DIAS DESC, ACORDOS_DESCUMPRIDOS DESC
LIMIT 20;

-- G08 · Quais clientes mais tomam crédito conosco? (top 10 por valor concedido)
SELECT c.ID_CLIENTE,
       CONCAT(pe.NOME,' ',pe.SOBRENOME)   AS CLIENTE,
       c.RENDA_DECLARADA,
       COUNT(*)                           AS QTD_EMPRESTIMOS,
       SUM(e.VALOR_APROVADO)              AS VALOR_TOTAL_CONCEDIDO,
       ROUND(AVG(e.VALOR_APROVADO),2)     AS TICKET_MEDIO,
       MAX(e.DATA_DESEMBOLSO)             AS ULTIMO_DESEMBOLSO
FROM EMPRESTIMO e
JOIN STATUS_EMPRESTIMO se ON se.ID_STATUS_EMPRESTIMO = e.STATUS_EMPRESTIMO
JOIN CLIENTE c            ON c.ID_CLIENTE = e.ID_CLIENTE
JOIN PESSOA pe            ON pe.ID_PESSOA = c.ID_PESSOA
WHERE se.NOME_STATUS IN ('PAGO','EM ANDAMENTO','RENEGOCIADO','QUITADO')
GROUP BY c.ID_CLIENTE, pe.NOME, pe.SOBRENOME, c.RENDA_DECLARADA
ORDER BY VALOR_TOTAL_CONCEDIDO DESC
LIMIT 10;

-- G09 · Por qual meio de pagamento os clientes mais pagam, e quanto é principal, juros e multa?
SELECT COALESCE(fp.NOME_FORMA_PAGTO,'(não informada)')                  AS FORMA_DE_PAGAMENTO,
       COUNT(DISTINCT l.ID_LANCAMENTO)                                   AS QTD_PAGAMENTOS,
       SUM(pl.VALOR_INICIAL_PAGO)                                        AS PRINCIPAL_RECEBIDO,
       SUM(IFNULL(pl.VALOR_JUROS_PAGO,0))                                AS JUROS_RECEBIDOS,
       SUM(IFNULL(pl.VALOR_MULTA_PAGO,0))                                AS MULTAS_RECEBIDAS,
       SUM(IFNULL(pl.VALOR_DESCONTO,0))                                  AS DESCONTOS_CONCEDIDOS,
       SUM(pl.VALOR_INICIAL_PAGO + IFNULL(pl.VALOR_JUROS_PAGO,0) + IFNULL(pl.VALOR_MULTA_PAGO,0)
           - IFNULL(pl.VALOR_DESCONTO,0))                                AS TOTAL_RECEBIDO
FROM PARCELA_LANCAMENTO pl
JOIN LANCAMENTO l           ON l.ID_LANCAMENTO = pl.ID_LANCAMENTO
LEFT JOIN FORMA_PAGTO fp    ON fp.ID_FORMA_PAGTO = l.ID_FORMA_PAGTO
GROUP BY FORMA_DE_PAGAMENTO
ORDER BY TOTAL_RECEBIDO DESC;

-- G10 · As renegociações funcionam? Quanto desconto damos e quantos acordos são cumpridos?
-- G10-A · Acordos por status
SELECT sa.NOME_STATUS_ACORDO                                   AS STATUS_ACORDO,
       COUNT(*)                                                AS QTD_ACORDOS,
       SUM(a.VALOR_DIVIDA_BASE)                                AS DIVIDA_BASE,
       SUM(a.VALOR_DESCONTO)                                   AS DESCONTO_CONCEDIDO,
       ROUND(100 * SUM(a.VALOR_DESCONTO) / NULLIF(SUM(a.VALOR_DIVIDA_BASE),0), 1) AS DESCONTO_MEDIO_PERC,
       ROUND(AVG(a.QTD_PARCELAS),1)                            AS PARCELAS_MEDIAS,
       SUM(a.VALOR_PARCELA * a.QTD_PARCELAS)                   AS VALOR_NEGOCIADO
FROM ACORDO a
JOIN STATUS_ACORDO sa ON sa.ID_STATUS_ACORDO = a.STATUS_ACORDO
GROUP BY sa.NOME_STATUS_ACORDO
ORDER BY QTD_ACORDOS DESC;

-- G10-B · Taxa de cumprimento dos acordos já encerrados
SELECT SUM(sa.NOME_STATUS_ACORDO = 'CUMPRIDO')    AS CUMPRIDOS,
       SUM(sa.NOME_STATUS_ACORDO = 'DESCUMPRIDO') AS DESCUMPRIDOS,
       ROUND(100 * SUM(sa.NOME_STATUS_ACORDO = 'CUMPRIDO') / NULLIF(COUNT(*),0), 1) AS TAXA_CUMPRIMENTO_PERC
FROM ACORDO a
JOIN STATUS_ACORDO sa ON sa.ID_STATUS_ACORDO = a.STATUS_ACORDO
WHERE sa.NOME_STATUS_ACORDO IN ('CUMPRIDO','DESCUMPRIDO');

-- G11 · Como está o desempenho da equipe?
-- G11-A · Comissões e volume originado por funcionário
SELECT f.ID_MATRICULA,
       CONCAT(pe.NOME,' ',pe.SOBRENOME)        AS FUNCIONARIO,
       d.NOME_DEPTO, cg.NOME_CARGO,
       COUNT(*)                                AS QTD_EMPRESTIMOS,
       SUM(e.VALOR_APROVADO)                   AS VALOR_APROVADO,
       SUM(IFNULL(ef.VALOR_COMISSAO,0))        AS COMISSAO_TOTAL,
       ROUND(100 * SUM(IFNULL(ef.VALOR_COMISSAO,0)) / NULLIF(SUM(e.VALOR_APROVADO),0), 2) AS COMISSAO_SOBRE_VOLUME_PERC
FROM EMPRESTIMO_FUNCIONARIO ef
JOIN FUNCIONARIO f   ON f.ID_MATRICULA = ef.ID_FUNCIONARIO
JOIN PESSOA pe       ON pe.ID_PESSOA = f.ID_PESSOA
JOIN EMPRESTIMO e    ON e.ID_EMPRESTIMO = ef.ID_EMPRESTIMO
LEFT JOIN DEPTO d    ON d.ID_DEPTO = f.ID_DEPTO
LEFT JOIN CARGO cg   ON cg.ID_CARGO = f.ID_CARGO
GROUP BY f.ID_MATRICULA, pe.NOME, pe.SOBRENOME, d.NOME_DEPTO, cg.NOME_CARGO
ORDER BY VALOR_APROVADO DESC;

-- G11-B · Produtividade de recuperação: acordos conduzidos por funcionário
SELECT f.ID_MATRICULA,
       CONCAT(pe.NOME,' ',pe.SOBRENOME)                                   AS FUNCIONARIO,
       COUNT(*)                                                           AS ACORDOS_REGISTRADOS,
       SUM(sa.NOME_STATUS_ACORDO IN ('APROVADO','CUMPRIDO'))              AS APROVADOS_OU_CUMPRIDOS,
       SUM(sa.NOME_STATUS_ACORDO = 'DESCUMPRIDO')                         AS DESCUMPRIDOS,
       SUM(a.VALOR_PARCELA * a.QTD_PARCELAS)                              AS VALOR_NEGOCIADO,
       ROUND(100 * SUM(a.VALOR_DESCONTO) / NULLIF(SUM(a.VALOR_DIVIDA_BASE),0), 1) AS DESCONTO_MEDIO_PERC
FROM ACORDO a
JOIN STATUS_ACORDO sa ON sa.ID_STATUS_ACORDO = a.STATUS_ACORDO
JOIN FUNCIONARIO f    ON f.ID_MATRICULA = a.ID_FUNCIONARIO
JOIN PESSOA pe        ON pe.ID_PESSOA = f.ID_PESSOA
GROUP BY f.ID_MATRICULA, pe.NOME, pe.SOBRENOME
ORDER BY VALOR_NEGOCIADO DESC;

-- G12 · Os scores mais baixos realmente geram mais inadimplência? (valida a política de faixas)
WITH ultimo_score AS (
  SELECT cs.ID_CLIENTE, cs.VALOR_SCORE
  FROM CONSULTA_SCORE cs
  WHERE cs.DATA_CONSULTA = (SELECT MAX(x.DATA_CONSULTA) FROM CONSULTA_SCORE x WHERE x.ID_CLIENTE = cs.ID_CLIENTE)
),
carteira AS (
  SELECT p.ID_CLIENTE,
         SUM(p.VALOR_INICIAL + p.VALOR_JUROS + p.VALOR_MULTA - p.VALOR_DESCONTO) AS ABERTO,
         SUM(CASE WHEN sp.NOME_STATUS_PARCELA = 'EM ATRASO'
                  THEN p.VALOR_INICIAL + p.VALOR_JUROS + p.VALOR_MULTA - p.VALOR_DESCONTO ELSE 0 END) AS ATRASO
  FROM PARCELA p
  JOIN STATUS_PARCELA sp ON sp.ID_STATUS_PARCELA = p.STATUS_PARCELA
  WHERE sp.NOME_STATUS_PARCELA IN ('A PAGAR','EM ATRASO','PARCIALMENTE PAGA')
  GROUP BY p.ID_CLIENTE
)
SELECT CASE WHEN us.VALOR_SCORE < 400 THEN '1) Até 399'
            WHEN us.VALOR_SCORE < 600 THEN '2) 400 a 599'
            WHEN us.VALOR_SCORE < 800 THEN '3) 600 a 799'
            ELSE '4) 800 ou mais' END                         AS FAIXA_SCORE,
       COUNT(*)                                                AS CLIENTES_COM_CARTEIRA,
       SUM(ca.ABERTO)                                          AS VALOR_EM_ABERTO,
       SUM(ca.ATRASO)                                          AS VALOR_EM_ATRASO,
       ROUND(100 * SUM(ca.ATRASO) / NULLIF(SUM(ca.ABERTO),0), 1) AS INADIMPLENCIA_PERC
FROM ultimo_score us
JOIN carteira ca ON ca.ID_CLIENTE = us.ID_CLIENTE
GROUP BY FAIXA_SCORE
ORDER BY FAIXA_SCORE;

-- G13 · Quanto vamos receber nos próximos meses? (previsão de caixa)
SELECT DATE_FORMAT(p.DATA_VENCIMENTO,'%Y-%m') AS MES_VENCIMENTO,
       COUNT(*)                               AS QTD_PARCELAS,
       SUM(p.VALOR_INICIAL + p.VALOR_JUROS + p.VALOR_MULTA - p.VALOR_DESCONTO) AS VALOR_PREVISTO
FROM PARCELA p
JOIN STATUS_PARCELA sp ON sp.ID_STATUS_PARCELA = p.STATUS_PARCELA
WHERE sp.NOME_STATUS_PARCELA IN ('A PAGAR','PARCIALMENTE PAGA')
  AND DATE(p.DATA_VENCIMENTO) >= CURDATE()
GROUP BY DATE_FORMAT(p.DATA_VENCIMENTO,'%Y-%m')
ORDER BY MES_VENCIMENTO
LIMIT 12;

-- G14 · Quais clientes potenciais (cadastro prévio) precisam ser acionados? (RF001/RF002)
SELECT c.ID_CLIENTE,
       CONCAT(pe.NOME,' ',pe.SOBRENOME)                    AS POTENCIAL_CLIENTE,
       c.DATA_CADASTRO,
       DATEDIFF(CURDATE(), DATE(c.DATA_CADASTRO))          AS DIAS_COMO_POTENCIAL,
       CASE WHEN DATEDIFF(CURDATE(), DATE(c.DATA_CADASTRO)) <= 7  THEN 'Quente (até 7 dias)'
            WHEN DATEDIFF(CURDATE(), DATE(c.DATA_CADASTRO)) <= 30 THEN 'Morno (8 a 30 dias)'
            ELSE 'Frio (mais de 30 dias)' END              AS PRIORIDADE_DE_CONTATO
FROM CLIENTE c
JOIN STATUS_CLIENTE sc ON sc.ID_STATUS_CLIENTE = c.STATUS_CLIENTE
JOIN PESSOA pe         ON pe.ID_PESSOA = c.ID_PESSOA
WHERE sc.NOME_STATUS = 'POTENCIAL'
ORDER BY DIAS_COMO_POTENCIAL ASC;

-- G15 · Em quanto tempo decidimos as propostas, e há propostas paradas?
-- G15-A · Tempo médio de decisão por mês
SELECT DATE_FORMAT(e.DATA_DECISAO,'%Y-%m')                              AS MES_DECISAO,
       COUNT(*)                                                         AS DECISOES,
       ROUND(AVG(TIMESTAMPDIFF(HOUR, e.DATA_CADASTRO, e.DATA_DECISAO)),1) AS HORAS_MEDIAS_ATE_DECISAO,
       MAX(TIMESTAMPDIFF(HOUR, e.DATA_CADASTRO, e.DATA_DECISAO))        AS PIOR_CASO_HORAS
FROM EMPRESTIMO e
WHERE e.DATA_DECISAO IS NOT NULL
GROUP BY DATE_FORMAT(e.DATA_DECISAO,'%Y-%m')
ORDER BY MES_DECISAO;

-- G15-B · Propostas paradas além do prazo aceitável
SELECT e.ID_EMPRESTIMO,
       CONCAT(pe.NOME,' ',pe.SOBRENOME)                 AS CLIENTE,
       se.NOME_STATUS                                   AS ETAPA_ATUAL,
       e.VALOR_SOLICITADO,
       e.DATA_CADASTRO,
       DATEDIFF(CURDATE(), DATE(IFNULL(e.DATA_ULTIMA_ALTERACAO, e.DATA_CADASTRO))) AS DIAS_SEM_MOVIMENTO
FROM EMPRESTIMO e
JOIN STATUS_EMPRESTIMO se ON se.ID_STATUS_EMPRESTIMO = e.STATUS_EMPRESTIMO
JOIN CLIENTE c            ON c.ID_CLIENTE = e.ID_CLIENTE
JOIN PESSOA pe            ON pe.ID_PESSOA = c.ID_PESSOA
WHERE se.NOME_STATUS IN ('PROPOSTA','EM ANALISE','AGUARDANDO FINANCEIRO')
  AND DATEDIFF(CURDATE(), DATE(IFNULL(e.DATA_ULTIMA_ALTERACAO, e.DATA_CADASTRO))) > @dias_fila_parada
ORDER BY DIAS_SEM_MOVIMENTO DESC;
