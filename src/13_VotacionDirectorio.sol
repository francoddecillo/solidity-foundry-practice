// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title VotacionDirectorio
 * @dev Enseña lógica de gobernanza corporativa, votaciones digitales y control de
 * seguridad contra el doble voto (mitigación de ataques lógicos).
 * Caso de negocio: La junta directiva (lista cerrada de direcciones) vota "A favor"
 * o "En contra" de una propuesta de inversión. La propuesta tiene una fecha de cierre.
 */
contract VotacionDirectorio {
    struct Propuesta {
        string descripcion;
        uint256 votosAFAvor;
        uint256 votosEnContra;
        uint256 limiteTiempo;
        bool ejecutada;
    }

    // Registro de los directores autorizados para votar
    mapping(address => bool) public esDirector;

    // Propuesta actual en votación
    Propuesta public propuestaActual;

    // Registro para saber si un director ya emitió su voto en la propuesta actual
    // Mapeo: Dirección del Director => Ha Votado (true/false)
    mapping(address => bool) public haVotado;

    address public secretarioGeneral;

    modifier soloSecretario() {
        require(msg.sender == secretarioGeneral, "Error: Solo el secretario puede administrar la votacion.");
        _;
    }

    modifier soloDirector() {
        require(esDirector[msg.sender], "Error: Acceso denegado. Solo los directores autorizados pueden votar.");
        _;
    }

    event PropuestaCreada(string descripcion, uint256 limiteTiempo);
    event VotoEmitido(address director, bool aFavor);
    event VotacionCerrada(uint256 votosAFavor, uint256 votosEnContra, bool aprobada);

    /**
     * @dev Configura al secretario y a los directores iniciales.
     */
    constructor(address[] memory _directoresIniciales) {
        secretarioGeneral = msg.sender;

        uint256 total = _directoresIniciales.length;
        for (uint256 i = 0; i < total; i++) {
            esDirector[_directoresIniciales[i]] = true;
        }
    }

    /**
     * @notice Registra una propuesta para votación corporativa.
     * @param _descripcion Resumen de la propuesta.
     * @param _duracionSegundos Tiempo de vigencia para recibir votos.
     */
    function iniciarVotacion(string memory _descripcion, uint256 _duracionSegundos) public soloSecretario {
        require(bytes(_descripcion).length > 0, "Error: La descripcion no puede estar vacia.");

        propuestaActual = Propuesta({
            descripcion: _descripcion,
            votosAFAvor: 0,
            votosEnContra: 0,
            limiteTiempo: block.timestamp + _duracionSegundos,
            ejecutada: false
        });

        // Emitir evento para anunciar la votación
        emit PropuestaCreada(_descripcion, propuestaActual.limiteTiempo);
    }

    /**
     * @notice Permite a un director emitir su voto.
     * @param _votoAFavor true si vota "A favor", false si vota "En contra".
     */
    function votar(bool _votoAFavor) public soloDirector {
        // Valida que el tiempo límite no haya expirado
        require(block.timestamp <= propuestaActual.limiteTiempo, "Error: El periodo de votacion ha expirado.");
        // Valida que no haya votado previamente para evitar fraude
        require(!haVotado[msg.sender], "Error: Ya has emitido tu voto para esta propuesta.");

        haVotado[msg.sender] = true;

        if (_votoAFavor) {
            propuestaActual.votosAFAvor++;
        } else {
            propuestaActual.votosEnContra++;
        }

        emit VotoEmitido(msg.sender, _votoAFavor);
    }

    /**
     * @notice Concluye oficialmente la votación y determina el resultado.
     * @return aprobada true si los votos a favor superan a los votos en contra, false de lo contrario.
     */
    function cerrarVotacion() public soloSecretario returns (bool aprobada) {
        require(!propuestaActual.ejecutada, "Error: La votacion ya ha sido ejecutada/cerrada.");
        require(block.timestamp > propuestaActual.limiteTiempo, "Error: El periodo de votacion aun esta activo.");

        propuestaActual.ejecutada = true;

        if (propuestaActual.votosAFAvor > propuestaActual.votosEnContra) {
            aprobada = true;
        } else {
            aprobada = false;
        }

        emit VotacionCerrada(propuestaActual.votosAFAvor, propuestaActual.votosEnContra, aprobada);
    }
}
