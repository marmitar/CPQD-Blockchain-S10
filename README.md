# Questionário 10

Em nossas aulas sobre desenvolvimento de smart contracts (contratos inteligentes), trabalhamos com a IDE Remix (<https://remix.ethereum.org/>), para o desenvolvimento de smart contracts em Solidity (<https://docs.soliditylang.org/en/v0.8.30/>) e deploy na rede de testes do Ethereum chamada Sepolia (<https://sepolia.etherscan.io/>). Em nossas aulas trabalhamos com um smart contract repleto de falhas de concepção. A sua tarefa aqui é corrigir parte destas falhas de desenvolvimento. Considere o código Solidy anexado a essa tarefa e faça as seguintes modificações:

1. Utilize o parâmetro owner que identifica o dono do smart contract para possibilitar que apenas o dono do contrato possa executar a função *commitment*;

2. Desenvolva uma função nova que permita que o valor de commitment seja revelado. Lembrando que a ideia inicial é que o dono do contrato possa armazenar no contrato um valor sorteado, através do hash deste valor concatenado com um valor de salt, ou seja, h(valor|salt). Por exemplo, caso o valor sorteado fosse 8 e o salt 123 teríamos: h(8|123). De forma que, posteriormente, poderíamos revelar tanto o salt quanto o valor sorteado e qualquer um com acesso ao contrato teria condições de verificar que o valor sorteado já havia sido registro na blockchain antes das apostas acontecerem. Repare que a função que revela o commitment também deve ser restrita ao dono do contrato. Calcular hashes em Solidity pode ser complexo e custoso, portanto considere que a verificação do hash possa ser realizada externalmente. Portanto, basta que a nova função permita que o valor uma vez sorteado seja revelado.

Para publicar e executar o smart contract em questão você precisará de Ether na rede de testes Sepolia, você pode conseguir essas criptomoedas de forma gratuita através do Ethereum Sepolia Faucet do Google: <https://cloud.google.com/application/web3/faucet/ethereum/sepolia>. Para interagir com a rede Sepolia através do Remix utilize o Metamask: <https://metamask.io/>.

Smart Contract de referência, `CPQD.sol`:

```solidity
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract CPQD {

    bytes32 hash;
    uint salt;
    mapping (uint => address []) public bets;

    function commitment (bytes32 h, uint s) public {
        hash = h;
        salt = s;
    }

    function bet(uint b) public {
        bets[b].push(msg.sender);
    }

    function get_results(uint secret) public view returns (address [] memory){
        return bets[secret];
    }
}
```

------------------------------------------------------------------------------------------------------------------------

Com base nos resultados alcançados nesta atividade, responda as perguntas que seguem.

## 1. O que foi necessário implementar para alcançar o objetivo da atividade?

Para o requerimento 1, foi necessário criar o parâmetro `owner` e proteger de modificações externas. Além disso, o parâmetro foi utilizado para proteger acesso de funções específicas, como a de `commmitment`. Esse parâmetro foi baseado na [interface `Ownable`](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol) do OpenZeppelin, que também tem o modificador `onlyOwner`.

Para a função de `reveal`, foram necessárias variáveis de estado (`isCommitted` e `isRevealed`) para garantir corretude na mudança de estado e para proteger de possíveis acessos indevidos no contrato. A verificação do hash foi implementada de forma otimizada, garantindo corretudo e eficiência. Além disso, o `salt` foi removido do `commitment`, por abrir breixas para ataques de força bruta.

Também foram implementadas proteções adicionais e tipos específicos do erro no código. Para garantir corretude, foram feitos testes avançados com as ferramentas `foundry` (execução com `forge test`) e foi utilizado um modelo de verificação formal (`z3`) que garante algumas invariantes do contrato (via `FOUNDRY_PROFILE=checker forge build`), além dos testes manuais na rede Sepolia Ethereum.

## 2. Qual é o endereço do contrato na rede de testes Sepolia?

[0xc8203b33b2D2d93eF923F107E7D74dB02fbdA945](https://sepolia.etherscan.io/address/0xc8203b33b2D2d93eF923F107E7D74dB02fbdA945)

Custou somente 320 Gwei. A versão anterior tinha sido 1382440 Gwei.

## 3. Link para 1 exemplo de transação executado na rede de testes Sepolia. Deve ser uma transação diferente do deploy do contrato.

- Commitment: [0xcbfa14709e93abec24acf2bdf47732d629784d733576e5fe0fffbe5821398061](https://sepolia.etherscan.io/tx/0xcbfa14709e93abec24acf2bdf47732d629784d733576e5fe0fffbe5821398061)
- Bet: [0x85f75bfb95483f016cdc36e450181b4bc009145deff78bef92f550cf14e80364](https://sepolia.etherscan.io/tx/0x85f75bfb95483f016cdc36e450181b4bc009145deff78bef92f550cf14e80364)
- Reveal: [0x68534903b8116acf53a8ca0a2dceb98d50cc7d4cc264a3cb842662e3fc71cc26](https://sepolia.etherscan.io/tx/0x68534903b8116acf53a8ca0a2dceb98d50cc7d4cc264a3cb842662e3fc71cc26)
- Restart: [0x7f666fc6002444fa20d0b528d2126f936954d2683960d302b968b0b50c526936](https://sepolia.etherscan.io/tx/0x7f666fc6002444fa20d0b528d2126f936954d2683960d302b968b0b50c526936)

## 4. Anexe uma print do seu Smart Contract.

```solidity
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.27 <0.9.0;

/**
 * @title A basic betting contract for the adventurous.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 * @notice Your prize can be extracted with the owner.
 * @dev Please use a valid commitment, otherwise the contract will be locked forever.
 */
contract CPQD {
    /**
     * @notice The contract creator, responsible for setting up the commitment and revealing the winners.
     * @dev This implementation is based on the following sources:
     * - https://docs.soliditylang.org/en/latest/contracts.html#constant-and-immutable-state-variables
     * - https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
     */
    address public immutable OWNER;

    /**
     * @notice Sets the owner of the contract to a specified address.
     * @param owner The address that will be set as the immutable owner.
     */
    constructor(address owner) {
        if (owner != address(0)) {
            OWNER = owner;
        } else {
            // owner not provided, fallback to sender
            OWNER = msg.sender;
        }
    }

    /**
     * @dev Account is not authorized to run the request function. This incident will be reported.
     * @param account Offending account.
     */
    error UnauthorizedAccount(address account);

    /**
     * @dev Ensure that only the owner can run the function.
     */
    modifier onlyOwner() {
        require(OWNER == msg.sender, UnauthorizedAccount(msg.sender));
        _;
    }

    // NOTE: Most attributes are private to protect against modification by extending this contract.

    /**
     * @dev Current commitment state.
     */
    bool private _isCommitted = false;
    /**
     * @dev Hash committed by the `owner` for reveal later. This should be the Keccak-256 hash of the secretly selected
     *  bet result with a randomly generated salt. The value and salt must be provided and will be checked during the
     *  reveal later.
     */
    bytes32 private _committedHash;
    // TODO: consider using a hash function that allows zero knowledge input validation

    /**
     * @dev Function can only be called after commitment, which has not happened yet.
     */
    error ContractNotCommittedYet();
    /**
     * @dev Function can only be called before commitment, but that has already happened.
     * @param committedHash The currently committed hash.
     */
    error ContractAlreadyCommitted(bytes32 committedHash);

    /**
     * @dev Ensure commitment is in the specified state for the function to run.
     * @param shouldBeCommitted When `true`, ensure hash is committed and, when `false`, ensure hash is not committed.
     */
    modifier committed(bool shouldBeCommitted) {
        if (shouldBeCommitted) {
            require(_isCommitted, ContractNotCommittedYet());
        } else {
            require(!_isCommitted, ContractAlreadyCommitted(_committedHash));
        }
        _;
    }

    /**
     * @notice Current commitment state.
     * @return `true` if the contract is in committed state and `false otherwise.
     */
    function isCommitted() external view returns (bool) {
        return _isCommitted;
    }

    /**
     * @notice Hash committed by the owner for reveal later.
     * @return Keccak-256 hash of a pair `(salt, value)` chosen by the owner.
     */
    function committedHash() external view committed(true) returns (bytes32) {
        return _committedHash;
    }

    /**
     * @dev Current reveal state.
     */
    bool private _isRevealed = false;
    /**
     * @dev Value revealed from commitment. Must be in the range of 0 to `MAXIMUM_VALUE`, otherwise the contract will
     *  enter a locked state.
     */
    uint8 private _revealedValue;
    /**
     * @dev The salt used for commitment secrecy. Should be randomly generated, but it's stored here for simplicity.
     */
    uint256 private _revealedSalt;

    /**
     * @dev Function can only be called after reveal, which has not happened yet.
     */
    error ContractNotRevealedYet();
    /**
     * @dev Function can only be called before reveal, but that has already happened.
     * @param revealedValue The value revealed from latest commitment.
     * @param revealedSalt The random salt revealed from latest commitment.
     */
    error ContractAlreadyRevealed(uint8 revealedValue, uint256 revealedSalt);

    /**
     * @dev Ensure commitment reveal is in the specified state for the function to run.
     * @param shouldBeRevealed When `true`, ensure value is revealed and, when `false`, ensure value is not revealed.
     */
    modifier revealed(bool shouldBeRevealed) {
        if (shouldBeRevealed) {
            require(_isRevealed, ContractNotRevealedYet());
        } else {
            require(!_isRevealed, ContractAlreadyRevealed(_revealedValue, _revealedSalt));
        }
        _;
    }

    /**
     * @notice Current reveal state.
     * @return `true` if the contract is in revealed state and `false otherwise.
     */
    function isRevealed() external view returns (bool) {
        return _isRevealed;
    }

    /**
     * @notice Chosen result for the bet.
     * @return Value the owner commited before the bet started.
     */
    function revealedValue() external view revealed(true) returns (uint8) {
        return _revealedValue;
    }

    /**
     * @notice Random salt used for protecting the bet.
     * @return Salt the owner commited before the bet started.
     */
    function revealedSalt() external view revealed(true) returns (uint256) {
        return _revealedSalt;
    }

    /**
     * @dev Value and salt provided by the owner does not match commitment hash. Contract possibly enters a locked
     *  state after this.
     * @param committedHash The hash provided by the owner during commitment.
     * @param salt Salt provided by the owner for reveal, possibly invalid.
     * @param value Value provided by the owner for reveal, possibly invalid.
     */
    error MismatchedReveal(bytes32 committedHash, uint256 salt, uint8 value);

    /**
     * @notice Hash `value` and `salt` to validate against committed hash.
     * @param salt Original salt for the committed hash.
     * @param value Original value for the committed hash.
     * @dev Throws `MismatchedReveal` if the inputs don't match. If `salt` is lost, then contract will forever be locked
     *  in "committed but not revealed" state.
     */
    function checkCommitment(uint256 salt, uint8 value) private view committed(true) {
        bytes32 computedHash;
        // See https://getfoundry.sh/forge/reference/forge-lint/#asm-keccak256
        assembly {
            mstore(0x00, salt)
            mstore(0x20, value) // padded to 32 bytes
            computedHash := keccak256(0x00, 0x40)
        }
        require(computedHash == _committedHash, MismatchedReveal(_committedHash, salt, value));
    }

    /**
     * @notice Predefined maximum accepted value for the `bet` function. Owner should respect this during commitment.
     * @dev Replace this with your preferred value.
     */
    uint8 public constant MAXIMUM_VALUE = 10;

    /**
     * @dev Owner tried revealing a value bigger than `MAXIMUM_VALUE`.
     * @param revealedValue Owner input.
     * @param maximumValue Same as `MAXIMUM_VALUE`.
     */
    error InvalidRevealedValue(uint8 revealedValue, uint8 maximumValue);
    /**
     * @dev User tried betting on a value bigger than `MAXIMUM_VALUE`.
     * @param bettedValue User input.
     * @param maximumValue Same as `MAXIMUM_VALUE`.
     */
    error InvalidBettedValue(uint8 bettedValue, uint8 maximumValue);

    /**
     * @dev Currently enrolled users, awaiting reveal by the owner.
     */
    address[][MAXIMUM_VALUE + 1] private bets;

    /**
     * @notice Commit hash for the result value to be revealed later. Bets can only be placed after this function has
     *  been called by the owner.
     * @param resultHash Keccak-256 hash of the pair `(salt, value)`, where `value` is the secretly chosen bet result
     *  and `salt` is a randomly generated byte string to protect against brute-force reveals.
     */
    function commitment(bytes32 resultHash) external onlyOwner committed(false) {
        _committedHash = resultHash;
        _isCommitted = true;
    }

    /**
     * @notice Reveal bet results for the users. The hash of `(salt, value)` must match previously committed hash.
     * @param value Selected result during commitment.
     * @param salt Random salt used for hiding `value` from brute-force reveal.
     */
    function reveal(uint8 value, uint256 salt) external onlyOwner committed(true) revealed(false) {
        checkCommitment(salt, value);
        require(value <= MAXIMUM_VALUE, InvalidRevealedValue(value, MAXIMUM_VALUE));

        _isRevealed = true;
        _revealedValue = value;
        _revealedSalt = salt;
    }

    /**
     * @notice Reset contract after results have been revealed.
     * @dev Even this function is not able able to clear a locked state if the salt is lost.
     */
    function restart() external onlyOwner revealed(true) {
        _isCommitted = false;
        _isRevealed = false;
        delete bets;
    }

    /**
     * @notice Bet on a specified value and wait for results.
     * @param bettedValue The correct value, hopefully.
     */
    function bet(uint8 bettedValue) external committed(true) revealed(false) {
        require(bettedValue <= MAXIMUM_VALUE, InvalidBettedValue(bettedValue, MAXIMUM_VALUE));
        // TODO: don't let users bet on locked contracts
        bets[bettedValue].push(msg.sender);
    }

    // NOTE: Renamed from 'get_results'. See https://getfoundry.sh/forge/reference/forge-lint/#mixed-case-function
    /**
     * @notice Get winners from revealed value.
     * @return List of addresses that betted on the correct value.
     */
    function getResults() external view revealed(true) returns (address[] memory) {
        return bets[_revealedValue];
    }
}
```
