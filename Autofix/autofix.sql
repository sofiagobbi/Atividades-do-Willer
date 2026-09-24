
CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    telefone VARCHAR(20) NOT NULL,
    cpf CHAR(11) NOT NULL UNIQUE,
    data_cadastro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE mecanicos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    especialidade VARCHAR(100) NOT NULL,
    valor_hora DECIMAL(10,2) NOT NULL CHECK (valor_hora > 0)
);

CREATE TABLE veiculos (
    id SERIAL PRIMARY KEY,
    cliente_id INTEGER NOT NULL,
    placa CHAR(7) NOT NULL UNIQUE,
    modelo VARCHAR(100) NOT NULL,
    marca VARCHAR(100) NOT NULL,
    ano INTEGER NOT NULL CHECK (ano > 0),

    CONSTRAINT fk_veiculo_cliente
        FOREIGN KEY (cliente_id)
        REFERENCES clientes(id)
);

CREATE TABLE ordens_servico (
    id SERIAL PRIMARY KEY,
    veiculo_id INTEGER NOT NULL,
    mecanico_id INTEGER NOT NULL,
    data_abertura TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valor_mao_obra DECIMAL(10,2) NOT NULL CHECK (valor_mao_obra >= 0),
    status VARCHAR(20) NOT NULL DEFAULT 'Em Aberto',

    CONSTRAINT fk_os_veiculo
        FOREIGN KEY (veiculo_id)
        REFERENCES veiculos(id),

    CONSTRAINT fk_os_mecanico
        FOREIGN KEY (mecanico_id)
        REFERENCES mecanicos(id),

    CONSTRAINT chk_status_os
        CHECK (status IN (
            'Em Aberto',
            'Em Andamento',
            'Concluida',
            'Cancelada'
        ))
);

CREATE TABLE pecas_os (
    id SERIAL PRIMARY KEY,
    os_id INTEGER NOT NULL,
    nome_peca VARCHAR(150) NOT NULL,
    quantidade INTEGER NOT NULL CHECK (quantidade > 0),
    valor_unitario DECIMAL(10,2) NOT NULL CHECK (valor_unitario > 0),

    CONSTRAINT fk_peca_os
        FOREIGN KEY (os_id)
        REFERENCES ordens_servico(id)
);

INSERT INTO clientes (nome, email, telefone, cpf)
VALUES
('João Silva', 'joao.silva@email.com', '(48) 99999-1111', '12345678901'),
('Fernanda Lima', 'fernanda.lima@email.com', '(48) 99999-2222', '23456789012'),
('Carlos Oliveira', 'carlos.oliveira@email.com', '(48) 99999-3333', '34567890123');

INSERT INTO mecanicos (nome, especialidade, valor_hora)
VALUES
('Marcos Souza', 'Motor', 120.00),
('Ana Pereira', 'Suspensão', 95.00),
('Ricardo Santos', 'Elétrica', 80.00);

INSERT INTO veiculos (cliente_id, placa, modelo, marca, ano)
VALUES
(1, 'ABC1D23', 'Civic', 'Honda', 2020),
(2, 'DEF4G56', 'Onix', 'Chevrolet', 2021),
(3, 'GHI7J89', 'Corolla', 'Toyota', 2019);

INSERT INTO ordens_servico
    (veiculo_id, mecanico_id, valor_mao_obra, status)
VALUES
(1, 1, 500.00, 'Concluida'),
(2, 2, 300.00, 'Em Andamento'),
(2, 3, 250.00, 'Concluida'),
(3, 1, 700.00, 'Em Aberto');

INSERT INTO pecas_os
    (os_id, nome_peca, quantidade, valor_unitario)
VALUES
(1, 'Filtro de Óleo', 1, 50.00),
(1, 'Óleo do Motor', 4, 35.00),
(2, 'Pastilha de Freio', 2, 120.00),
(3, 'Lâmpada Automotiva', 2, 45.00);

SELECT
    v.modelo,
    v.marca,
    v.placa,
    c.nome AS proprietario,
    c.telefone
FROM veiculos v
INNER JOIN clientes c
    ON c.id = v.cliente_id
ORDER BY v.marca, v.modelo;

SELECT
    os.id AS id_os,
    v.placa,
    v.modelo,
    os.data_abertura,
    m.nome AS mecanico_responsavel,
    os.status
FROM ordens_servico os
INNER JOIN veiculos v
    ON v.id = os.veiculo_id
INNER JOIN clientes c
    ON c.id = v.cliente_id
INNER JOIN mecanicos m
    ON m.id = os.mecanico_id
WHERE c.nome = 'Fernanda Lima'
ORDER BY os.data_abertura;

SELECT
    os.id AS id_os,
    v.placa,
    m.nome AS mecanico,
    os.valor_mao_obra,
    COALESCE(
        SUM(p.quantidade * p.valor_unitario),
        0
    ) AS valor_pecas,
    os.valor_mao_obra +
    COALESCE(
        SUM(p.quantidade * p.valor_unitario),
        0
    ) AS valor_total
FROM ordens_servico os
INNER JOIN veiculos v
    ON v.id = os.veiculo_id
INNER JOIN mecanicos m
    ON m.id = os.mecanico_id
LEFT JOIN pecas_os p
    ON p.os_id = os.id
GROUP BY
    os.id,
    v.placa,
    m.nome,
    os.valor_mao_obra
ORDER BY os.id;

SELECT
    id,
    nome,
    especialidade,
    valor_hora
FROM mecanicos
WHERE valor_hora > 90.00
ORDER BY valor_hora DESC;

SELECT
    m.especialidade,
    SUM(os.valor_mao_obra) AS total_faturado
FROM ordens_servico os
INNER JOIN mecanicos m
    ON m.id = os.mecanico_id
WHERE os.status = 'Concluida'
GROUP BY m.especialidade
ORDER BY m.especialidade;