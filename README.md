# Solidity con Foundry y Anvil

> Proyecto personal de aprendizaje y práctica de contratos inteligentes en Solidity, utilizando Foundry, Anvil y Cast. El trabajo recorre **15 contratos** con ejemplos de lógica empresarial, despliegues locales, pruebas automatizadas y análisis de gas.

Este repositorio documenta mi proceso de aprendizaje: desde el almacenamiento de datos en blockchain hasta contratos de custodia de ETH, votaciones, autorizaciones multifirma y suscripciones. Las prácticas se realizaron en **Debian 13** con **Visual Studio Code** y una blockchain local de **Anvil**.

**Alcance:** material educativo. Los contratos no deben considerarse auditados ni aptos para administrar fondos reales sin una revisión adicional de seguridad.

## Tecnologías utilizadas

- **Solidity:** lenguaje de los contratos inteligentes.
- **Foundry / Forge:** compilación, despliegue, pruebas y reportes de gas.
- **Anvil:** blockchain Ethereum local con cuentas de prueba.
- **Cast:** interacción con contratos y consultas RPC desde la terminal.
- **VS Code y Debian 13:** entorno de desarrollo.

## Contenido: los 15 contratos

| Nº | Contrato | Conceptos practicados |
| --- | --- | --- |
| 01 | `AlmacenamientoSimple` | Variables de estado, lectura y escritura. |
| 02 | `RegistroActivos` | Constructor, `uint256`, `bool` y `address`. |
| 03 | `ControlAccesoBasico` | `msg.sender`, `modifier`, `require` y roles. |
| 04 | `RegistroProveedores` | Estructuras (`struct`) y validaciones. |
| 05 | `DirectorioClientes` | `mapping` y registros asociados a direcciones. |
| 06 | `ListaProveedoresCompletos` | Combinación de `mapping` y `struct`. |
| 07 | `BuzonSugerencias` | Arrays dinámicos, ciclos y contadores. |
| 08 | `CajaChica` | ETH, `payable`, `receive()` y retiros. |
| 09 | `NominaMensual` | Eventos y pagos a empleados. |
| 10 | `SeguimientoEnvios` | `enum` y máquinas de estados. |
| 11 | `FideicomisoSimple` | Escrow, roles y vencimientos. |
| 12 | `RepartoDividendos` | Porcentajes, redondeo y reparto de ETH. |
| 13 | `VotacionDirectorio` | Gobernanza, plazos y prevención del doble voto. |
| 14 | `ContratoMultifirmaLigero` | Tesorería multifirma y aprobaciones 2 de 3. |
| 15 | `SuscripcionServicio` | Suscripciones SaaS, renovaciones y cobros. |

Los nombres de archivo de `src/` pueden conservar prefijos numéricos (por ejemplo, `15_SuscripcionServicio.sol`). Al ejecutar comandos, utilizá **la ruta real del archivo** de tu repositorio.

## Organización del proyecto

```text
.
├── foundry.toml
├── src/               # Contratos Solidity
├── test/              # Pruebas automáticas de Foundry (*.t.sol)
├── script/            # Espacio para scripts de despliegue
└── lib/               # Dependencias, incluido forge-std
```

## Requisitos

1. Tener instalado [Foundry](https://getfoundry.sh/) (`forge`, `cast` y `anvil`).
2. Contar con Git y un editor como VS Code.
3. Utilizar una terminal Bash o compatible para los ejemplos siguientes.

> Todos los ejemplos de despliegue están pensados para **Anvil en localhost** y cuentas **exclusivamente de prueba**. Nunca publiques claves privadas reales ni las incluyas en commits.

## Inicio rápido

### 1. Entrar al proyecto y compilar

```bash
forge build
```

### 2. Iniciar la red local — Terminal 1

```bash
anvil
```

Anvil utiliza normalmente el endpoint `http://127.0.0.1:8545` y muestra cuentas de prueba financiadas.

### 3. Configurar variables — Terminal 2

```bash
export RPC_URL=http://127.0.0.1:8545
export PRIVATE_KEY=0xCLAVE_PRIVADA_DE_PRUEBA_DE_ANVIL
```

Reemplazá el valor de ejemplo con la clave de una cuenta **local de Anvil**. No subas claves privadas al repositorio.

### 4. Ejecutar las pruebas

```bash
forge test
forge test -vv
forge test --gas-report
```

Para ejecutar solamente las pruebas del servicio de suscripciones:

```bash
forge test --match-contract SuscripcionServicioTest -vv
```

Para ejecutar un test concreto:

```bash
forge test --match-test testRenovacionAnticipada -vv
```

`forge test` utiliza una EVM de pruebas aislada y **no requiere que Anvil esté funcionando**.

## Despliegue de ejemplo: SuscripcionServicio

El contrato de suscripciones recibe el precio mensual expresado en wei en su constructor. Para configurar **0,1 ETH**, desplegamos con `100000000000000000` wei:

```bash
forge create src/15_SuscripcionServicio.sol:SuscripcionServicio \
  --rpc-url "$RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --broadcast \
  --constructor-args 100000000000000000
```

Copiá la dirección indicada en `Deployed to:` y guardala:

```bash
export SUSCRIPCION=0xDIRECCION_DESPLEGADA
```

### Consultar el precio

```bash
cast call "$SUSCRIPCION" \
  "costoMensual()(uint256)" \
  --rpc-url "$RPC_URL"
```

### Pagar una suscripción con otra cuenta de Anvil

```bash
export PRIVATE_KEY_CLIENTE=0xCLAVE_DE_OTRA_CUENTA_DE_PRUEBA

cast send "$SUSCRIPCION" \
  "pagarSuscripcion()" \
  --value 0.1ether \
  --private-key "$PRIVATE_KEY_CLIENTE" \
  --rpc-url "$RPC_URL"
```

### Consultar el estado de la suscripción

```bash
export CLIENTE=0xDIRECCION_DE_LA_CUENTA_CLIENTE

cast call "$SUSCRIPCION" \
  "esSuscripcionActiva(address)(bool)" \
  "$CLIENTE" \
  --rpc-url "$RPC_URL"
```

### Consultar el balance del contrato

```bash
cast balance "$SUSCRIPCION" --ether --rpc-url "$RPC_URL"
```

## Comandos de uso frecuente

| Comando | Uso |
| --- | --- |
| `anvil` | Iniciar la blockchain local. |
| `forge build` | Compilar los contratos. |
| `forge test` | Ejecutar todas las pruebas. |
| `forge test -vv` | Mostrar información adicional de las pruebas. |
| `forge test -vvvv` | Consultar trazas más detalladas para depurar. |
| `forge test --gas-report` | Generar un reporte de consumo de gas. |
| `forge test --match-contract NombreTest` | Filtrar pruebas por contrato. |
| `forge test --match-test nombreTest` | Filtrar por nombre de test. |
| `forge fmt` | Formatear los archivos Solidity. |
| `forge create` | Desplegar un contrato. |
| `cast call` | Leer datos sin modificar el estado. |
| `cast send` | Firmar y enviar una transacción. |
| `cast balance` | Consultar el balance de ETH. |
| `cast rpc eth_accounts` | Ver las cuentas de Anvil. |

**Regla práctica:** `cast call` consulta; `cast send` envía transacciones que pueden modificar el estado y consumen gas.

### Simular el paso del tiempo en Anvil

```bash
# Avanzar un día
cast rpc evm_increaseTime 86400 --rpc-url "$RPC_URL"
cast rpc evm_mine --rpc-url "$RPC_URL"

# Avanzar 30 días
cast rpc evm_increaseTime 2592000 --rpc-url "$RPC_URL"
cast rpc evm_mine --rpc-url "$RPC_URL"
```

## Herramientas de prueba de Foundry

Durante las prácticas se usaron las *cheatcodes* de `forge-std`:

| Herramienta | Finalidad |
| --- | --- |
| `setUp()` | Preparar el estado antes de cada prueba. |
| `vm.deal(cuenta, monto)` | Asignar ETH ficticio a una cuenta. |
| `vm.prank(cuenta)` | Simular otro `msg.sender` en la siguiente llamada. |
| `vm.startPrank(cuenta)` y `vm.stopPrank()` | Simular un remitente durante varias llamadas. |
| `vm.warp(timestamp)` | Cambiar `block.timestamp` dentro de un test. |
| `vm.expectRevert(...)` | Verificar que una operación se revierte. |
| `vm.expectEmit(...)` | Verificar que se emite el evento esperado. |
| `assertEq`, `assertTrue`, `assertFalse` | Comprobar resultados. |

Ejemplo de prueba de acceso temporal:

```solidity
vm.deal(cliente, 1 ether);
vm.prank(cliente);
servicio.pagarSuscripcion{value: 0.1 ether}();

assertTrue(servicio.esSuscripcionActiva(cliente));

vm.warp(servicio.expiracionSuscripcion(cliente));
assertFalse(servicio.esSuscripcionActiva(cliente));
```

**Diferencia clave:** `vm.warp()` altera el reloj de las pruebas de Foundry; `evm_increaseTime` altera el reloj de **Anvil**.

## Aprendizajes de seguridad y pruebas

Las prácticas incluyeron casos normales, permisos incorrectos, intentos de ejecución duplicada, fechas límite y transferencias fallidas. Algunos comportamientos que conviene revisar antes de utilizar contratos en producción:

- **`VotacionDirectorio`:** el `mapping haVotado` no distingue propuestas, por lo que un director puede quedar bloqueado después de votar en una propuesta anterior. Además, el secretario puede reemplazar una propuesta todavía activa.
- **`ContratoMultifirmaLigero`:** se requieren dos aprobaciones para ejecutar un retiro y se evita la aprobación duplicada por propuesta; aun así, el constructor no exige que las tres direcciones sean diferentes y se admiten propuestas de monto cero.
- **`RepartoDividendos`:** las divisiones enteras producen redondeos; el último socio recibe el remanente para que no queden wei pendientes. Las llamadas externas requieren revisar posibles escenarios de reentrancia.
- **`FideicomisoSimple`:** la ejecución depende de permisos y de `block.timestamp`; es importante probar tanto la fecha límite exacta como el segundo posterior.
- **`SuscripcionServicio`:** el propietario puede establecer un costo mensual igual a cero; además, las renovaciones requieren transacciones iniciadas por el cliente, no son cobros automáticos.
- **Transferencias de ETH:** comprobar el resultado de `call`, tratar los fallos y analizar el patrón *Checks-Effects-Interactions*.

Que un test muestre **`PASS`** significa que se cumplió lo que ese test verificó; **no implica que el contrato sea seguro**. Como siguiente etapa, conviene ampliar las pruebas con *fuzz testing*, invariantes y una revisión de seguridad antes de operar con fondos reales.

## Repaso rápido

```bash
# Terminal 1
anvil

# Terminal 2
export RPC_URL=http://127.0.0.1:8545
forge build
forge test -vv
forge test --gas-report
```

## Créditos y fuente original

Esta práctica está **basada en los contratos y ejercicios de la clase 4** del repositorio **[diplomado-usach-training-dapp-contracts](https://github.com/cjbaezilla/diplomado-usach-training-dapp-contracts)**, publicado por **[@cjbaezilla](https://github.com/cjbaezilla)**.

**Material original utilizado como referencia:**

- [Diplomado USACH — Contratos de la clase 4](https://github.com/cjbaezilla/diplomado-usach-training-dapp-contracts/tree/main/contracts/clase_4)

Este repositorio consiste en documentar el proceso personal de estudio, ejecutar los contratos en un entorno local, practicar las interacciones por consola y desarrollar/organizar pruebas automatizadas y apuntes de aprendizaje. **La autoría del material base corresponde a sus creadores originales**; este repositorio no pretende atribuirse su creación ni representar oficialmente al proyecto o a la institución.
