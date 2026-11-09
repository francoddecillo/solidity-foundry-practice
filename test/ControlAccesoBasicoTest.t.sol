
 // SPDX-License-Identifier: MIT
 pragma solidity ^0.8.0;

 import {Test} from "forge-std/Test.sol";
 import {ControlAccesoBasico} from "../src/3_ControlAccesoBasico.sol";

 contract ControlAccesoBasicoTest is Test {

     ControlAccesoBasico acceso;

     address intruso = address(0x1234);
     address nuevoGerente = address(0x5678);

     function setUp() public {
         acceso = new ControlAccesoBasico(
             "Av. Rivadavia 1000"
         );
     }

     function testGerentePuedeActualizar() public {
         acceso.actualizarDireccionOficina(
             "Av. Corrientes 1500"
         );

         assertEq(
             acceso.direccionOficina(),
             "Av. Corrientes 1500"
         );
     }

     function testIntrusoNoPuedeActualizar() public {
         vm.prank(intruso);
         
         // La próxima llamada al contrato debe revertirse con este error
         vm.expectRevert(
             bytes(
                 "Error: Solo el Gerente General puede realizar esta accion."
             )
         );

         acceso.actualizarDireccionOficina(
             "Direccion fraudulenta"
         );
     }

     function testTransferirGerencia() public {
         acceso.transferirGerencia(nuevoGerente);

         assertEq(
             acceso.gerenteGeneral(),
             nuevoGerente
         );
     }

     function testNoPermiteGerenteNulo() public {
         vm.expectRevert(
             bytes(
                 "Error: La nueva direccion no puede ser nula (address 0)."
             )
         );

         acceso.transferirGerencia(address(0));
     }
 }
