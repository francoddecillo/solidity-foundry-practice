// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {RegistroProveedores} from "../src/4_RegistroProveedores.sol";

contract RegistroProveedoresTest is Test {
    RegistroProveedores registro;

    address intruso = address(0x1234);

    function setUp() public {
        registro = new RegistroProveedores();
    }

    // TEST 1: Registro inicial
    function testRegistrarProveedor() public {
        registro.registrarProveedor("Tecnologia Argentina SA", "30712345678");
        // Desestructuración de una tupla:
        (string memory nombre, string memory rut, uint256 volumen, bool verificado) = registro.proveedorRegistrado();

        assertEq(nombre, "Tecnologia Argentina SA");
        assertEq(rut, "30712345678");
        assertEq(volumen, 0);
        assertTrue(verificado);
    }

    // TEST 2: Compras acumuladas
    function testComprasAcumuladas() public {
        registro.registrarProveedor("Tecnologia Argentina SA", "30712345678");

        registro.registrarCompra(1250);
        registro.registrarCompra(750);

        // Recuperación de únicamente el dato que necesito de la tupla
        (,, uint256 volumen,) = registro.proveedorRegistrado();

        assertEq(volumen, 2000);
    }

    // TEST 3: Compra bloqueada
    function testCompraSinVerificacion() public {
        registro.registrarProveedor("Tecnologia Argentina SA", "30712345678");

        registro.establecerVerificacion(false);

        vm.expectRevert(bytes("Error: El proveedor no esta verificado o no esta registrado."));

        registro.registrarCompra(500);
    }

    // TEST 4: Acceso no autorizado
    function testIntrusoNoPuedeRegistrar() public {
        vm.expectRevert(bytes("Error: Solo el administrador de compras puede realizar esto."));

        vm.prank(intruso);

        registro.registrarProveedor("Proveedor Falso", "99999999");
    }

    // TEST 5: Sobrescribir un proveedor
    function testSobrescribirProveedor() public {
        registro.registrarProveedor("Proveedor A", "11111111");

        registro.registrarCompra(1000);
        registro.establecerVerificacion(false);

        registro.registrarProveedor("Proveedor B", "22222222");

        (string memory nombre, string memory rut, uint256 volumen, bool verificado) = registro.proveedorRegistrado();

        assertEq(nombre, "Proveedor B");
        assertEq(rut, "22222222");
        assertEq(volumen, 0);
        assertTrue(verificado);
    }
}
