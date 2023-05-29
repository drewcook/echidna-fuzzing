pragma solidity ^0.6.0;

// Setup external testing
import "../uni-v2/UniswapV2ERC20.sol";
import "../uni-v2/UniswapV2Pair.sol";
import "../uni-v2/UniswapV2Factory.sol";
import "../libraries/UniswapV2Library.sol";

// External testing contract which will call our target contract(s)
contract Users {
    // Call other contracts in the system
    function proxy(
        address target,
        bytes memory data
    ) public returns (bool success, bytes memory returnData) {
        return target.call(data);
    }
}

contract Setup {
    // 1. What state do we need in our setup?
    // - what do we need in a pair?
    UniswapV2ERC20 testToken1;
    UniswapV2ERC20 testToken2;
    UniswapV2Factory factory;
    UniswapV2Pair pair;
    Users user;
    bool completed;

    // 2. Initilize our test state variables
    // - create a pair
    // - create a user to simulate an EOA which will call the contract(s)
    constructor() public {
        testToken1 = new UniswapV2ERC20();
        testToken2 = new UniswapV2ERC20();
        factory = new UniswapV2Factory(address(this)); // echidna gets to set the pair
        user = new Users();
        pair = UniswapV2Pair(
            factory.createPair(address(testToken1), address(testToken2))
        );
    }

    // 3. Create some helpers that can be used for our preconditions

    // - ensure we only mint when there are no tokens left for the user, so we won't mint on every test run
    function _mintTokens(uint amount1, uint amount2) internal {
        testToken1.mint(address(this), amount1);
        testToken2.mint(address(this), amount2);
        completed = true;
    }

    // - ensures a value is between a certain range
    function _between(
        uint value,
        uint low,
        uint high
    ) internal pure returns (uint) {
        return (low + (value % (high - low + 1)));
    }
}
