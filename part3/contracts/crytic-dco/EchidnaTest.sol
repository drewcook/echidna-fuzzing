pragma solidity ^0.6.0;

import "./Setup.sol";

/*
	We want to create a test contract that will test for different invariants against Uni-V2
	Test:
	- That adding liquidiy (liquidity provisioning) for any/both token increases the K invariant value (tokenA*tokenB=k)
	- That swapping tokens that don't exist in the pool cannot occur
*/

// We want to inherit all of the state and helpers that we wrote in Setup
contract EchidnaTest is Setup {
    // Testing liquidity provisioning increasing the K invariant
    // We want to mint these amounts on every call so we can take advantage of the fuzzing and random inputs
    function testProvideLiquidity(uint amount1, uint amount2) public {
        // 1. Preconditions

        // - limit our input space
        // we should bound the amount values in between MIN_LIQUIDITY and XX
        amount1 = _between(amount1, 1000, uint(-1)); // up to max uint (2**256-1)
        amount2 = _between(amount2, 1000, uint(-1));

        // - mint some tokens so the user has some to provide
        if (!completed) {
            _mintTokens(amount1, amount2);
        }

        // - get our state before the action so we can compare after
        uint lpTokenBalanceBefore = pair.balanceOf(address(user)); // how may LP tokens user has (should increase after providing liquidity)
        (uint reserve0Before, uint reserve1Before, ) = pair.getReserves(); // get the contract reserves
        uint kBefore = reserve0Before * reserve1Before; // these are uint112 from the contract, so no overflow in uint256

        // - transfer each of the tokens into the pair contract
        (bool success1, ) = user.proxy(
            address(testToken1),
            abi.encodeWithSelector(
                testToken1.transfer.selector,
                address(pair),
                amount1
            )
        );
        (bool success2, ) = user.proxy(
            address(testToken2),
            abi.encodeWithSelector(
                testToken2.transfer.selector,
                address(pair),
                amount2
            )
        );
        // - ensure both of these have succeeded
        require(success1 && success2);

        // 2. Action

        // - call our pair address and use our custom external mint() function we wrote, this allows echidna to actually call the private function
        (bool success3, ) = user.proxy(
            address(pair),
            abi.encodeWithSelector(
                bytes4(keccak256("mint(address)")),
                address(user)
            )
        );

        // 3. Postconditions

        // - assert that the values are accurate
        if (success3) {
            // get after values
            uint lpTokenBalanceAfter = pair.balanceOf(address(user));
            (uint reserve0After, uint reserve1After, ) = pair.getReserves();
            uint kAfter = reserve0After * reserve1After;

            // - LP tokens have been added correctly and increased for the user
            assert(lpTokenBalanceBefore < lpTokenBalanceAfter);

            // - the pool invariant should be increased after providing liquidity
            assert(kBefore < kAfter);
        }
    }
}
