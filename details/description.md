# Questionário 10

Em nossas aulas sobre desenvolvimento de smart contracts (contratos inteligentes), trabalhamos com a IDE Remix (<https://remix.ethereum.org/>), para o desenvolvimento de smart contracts em Solidity (<https://docs.soliditylang.org/en/v0.8.30/>) e deploy na rede de testes do Ethereum chamada Sepolia (<https://sepolia.etherscan.io/>). Em nossas aulas trabalhamos com um smart contract repleto de falhas de concepção. A sua tarefa aqui é corrigir parte destas falhas de desenvolvimento. Considere o código Solidy anexado a essa tarefa e faça as seguintes modificações:

1. Utilize o parâmetro owner que identifica o dono do smart contract para possibilitar que apenas o dono do contrato possa executar a função *commitment*;

2. Desenvolva uma função nova que permita que o valor de commitment seja revelado. Lembrando que a ideia inicial é que o dono do contrato possa armazenar no contrato um valor sorteado, através do hash deste valor concatenado com um valor de salt, ou seja, h(valor|salt). Por exemplo, caso o valor sorteado fosse 8 e o salt 123 teríamos: h(8|123). De forma que, posteriormente, poderíamos revelar tanto o salt quanto o valor sorteado e qualquer um com acesso ao contrato teria condições de verificar que o valor sorteado já havia sido registro na blockchain antes das apostas acontecerem. Repare que a função que revela o commitment também deve ser restrita ao dono do contrato. Calcular hashes em Solidity pode ser complexo e custoso, portanto considere que a verificação do hash possa ser realizada externalmente. Portanto, basta que a nova função permita que o valor uma vez sorteado seja revelado.

Para publicar e executar o smart contract em questão você precisará de Ether na rede de testes Sepolia, você pode conseguir essas criptomoedas de forma gratuita através do Ethereum Sepolia Faucet do Google: <https://cloud.google.com/application/web3/faucet/ethereum/sepolia>. Para interagir com a rede Sepolia através do Remix utilize o Metamask: <https://metamask.io/>.

Smart Contract de referência: [CPQD.sol](./CPQD.sol)

------------------------------------------------------------------------------------------------------------------------

Com base nos resultados alcançados nesta atividade, responda as perguntas que seguem.

1. O que foi necessário implementar para alcançar o objetivo da atividade?
2. Qual é o endereço do contrato na rede de testes Sepolia?
3. Link para 1 exemplo de transação executado na rede de testes Sepolia. Deve ser uma transação diferente do deploy do contrato.
4. Anexe uma print do seu Smart Contract.
