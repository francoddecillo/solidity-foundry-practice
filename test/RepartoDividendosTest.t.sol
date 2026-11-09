
 // SPDX-License-Identifier: MIT
 pragma solidity ^0.8.0;

 import {Test} from "forge-std/Test.sol";
 import {RepartoDividendos} from "../src/12_RepartoDividendos.sol";

 // Contrato auxiliar que rechaza recibir Ether
 contract ReceptorQueRechaza {
     receive() external payable {
         revert("No acepto Ether");
     }
 }

 contract RepartoDividendosTest is Test {

     RepartoDividendos reparto;

     address payable socioA = payable(address(0xA11CE));
     address payable socioB = payable(address(0xB0B));
     address payable socioC = payable(address(0xCAFE));

     address pagador = address(0xD00D);

     event DividendosRepartidos(
         uint256 montoTotal,
         uint256 cuotaA,
         uint256 cuotaB,
         uint256 cuotaC
     );

     function setUp() public {
         reparto = new RepartoDividendos(
             socioA,
             socioB,
             socioC
         );

         vm.deal(pagador, 10 ether);
     }

     // TEST 1: Configuracion inicial
     function testConfiguracionInicial() public view {
         assertEq(reparto.socioA(), socioA);
         assertEq(reparto.socioB(), socioB);
         assertEq(reparto.socioC(), socioC);

         assertEq(reparto.PORCENTAJE_A(), 50);
         assertEq(reparto.PORCENTAJE_B(), 30);
         assertEq(reparto.PORCENTAJE_C(), 20);
     }

     // TEST 2: Repartir 1 ETH
     function testRepartirUnEther() public {
         vm.prank(pagador);
         reparto.recibirYRepartir{value: 1 ether}();

         assertEq(socioA.balance, 0.5 ether);
         assertEq(socioB.balance, 0.3 ether);
         assertEq(socioC.balance, 0.2 ether);

         assertEq(address(reparto).balance, 0);
     }

     // TEST 3: Comprobar evento
     function testEventoDividendos() public {
         vm.expectEmit(
             false, false, false, true,
             address(reparto)
         );

         emit DividendosRepartidos(
             1 ether,
             0.5 ether,
             0.3 ether,
             0.2 ether
         );

         vm.prank(pagador);
         reparto.recibirYRepartir{value: 1 ether}();
     }

     // TEST 4: Recibir ETH sin especificar funcion
     function testReceiveDirecto() public {
         vm.prank(pagador);

         (bool exito, ) =
             payable(address(reparto)).call{value: 1 ether}("");

         assertTrue(exito);

         assertEq(socioA.balance, 0.5 ether);
         assertEq(socioB.balance, 0.3 ether);
         assertEq(socioC.balance, 0.2 ether);
     }

     // TEST 5: Rechazar deposito de cero
     function testRechazarDepositoCero() public {
         vm.expectRevert(
             abi.encodeWithSignature(
                 "Error(string)",
                 unicode"Error: El monto depositado es demasiado pequeño."
             )
         );

         reparto.recibirYRepartir{value: 0}();
     }

     // TEST 6: Rechazar exactamente 100 wei
     function testRechazarCienWei() public {
         vm.expectRevert(
             abi.encodeWithSignature(
                 "Error(string)",
                 unicode"Error: El monto depositado es demasiado pequeño."
             )
         );

         vm.prank(pagador);
         reparto.recibirYRepartir{value: 100 wei}();
     }

     // TEST 7: Redondeo al repartir 101 wei
     function testRedondeoCientoUnWei() public {
         vm.prank(pagador);
         reparto.recibirYRepartir{value: 101 wei}();

         assertEq(socioA.balance, 50);
         assertEq(socioB.balance, 30);
         assertEq(socioC.balance, 21);

         assertEq(address(reparto).balance, 0);
     }

     // TEST 8: Varios depositos acumulados
     function testVariosDepositos() public {
         vm.startPrank(pagador);

         reparto.recibirYRepartir{value: 1 ether}();
         reparto.recibirYRepartir{value: 2 ether}();

         vm.stopPrank();

         assertEq(socioA.balance, 1.5 ether);
         assertEq(socioB.balance, 0.9 ether);
         assertEq(socioC.balance, 0.6 ether);

         assertEq(address(reparto).balance, 0);
     }

     // TEST 9: Socio A no puede ser direccion cero
     function testRechazarSocioACero() public {
         vm.expectRevert("Error: Direcciones invalidas.");

         new RepartoDividendos(
             payable(address(0)),
             socioB,
             socioC
         );
     }

     // TEST 10: Socio B no puede ser direccion cero
     function testRechazarSocioBCero() public {
         vm.expectRevert("Error: Direcciones invalidas.");

         new RepartoDividendos(
             socioA,
             payable(address(0)),
             socioC
         );
     }

     // TEST 11: Socio C no puede ser direccion cero
     function testRechazarSocioCCero() public {
         vm.expectRevert("Error: Direcciones invalidas.");

         new RepartoDividendos(
             socioA,
             socioB,
             payable(address(0))
         );
     }

     // TEST 12: Si un socio rechaza ETH,
     // toda la transaccion debe revertirse
     function testRechazoRevierteTodo() public {
         ReceptorQueRechaza receptor =
             new ReceptorQueRechaza();

         RepartoDividendos otroReparto =
             new RepartoDividendos(
                 payable(address(receptor)),
                 socioB,
                 socioC
             );

         vm.expectRevert(
             "Error: Fallo al transferir a uno de los socios."
         );

         vm.prank(pagador);

         otroReparto.recibirYRepartir{value: 1 ether}();

         // Nadie debe haber cobrado
         assertEq(socioB.balance, 0);
         assertEq(socioC.balance, 0);
         assertEq(address(otroReparto).balance, 0);
     }
 }
