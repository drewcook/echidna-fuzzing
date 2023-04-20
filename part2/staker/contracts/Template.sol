pragma solidity ^0.8.17;

import "./Staker.sol";
// Run 'echidna .' to compile everything in this project, since it needs to compile third-party dependencies also
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Using inheritance to create custom behavior for what we are doing/testing
// ie the ERC20 does not a have public mint function and we need to load a balance to the EchidnaTemplate contract prior to testing
contract MockERC20 is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {}

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }

    // Override the transferFrom function and remove the allowance requirement for our test
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        address spender = msg.sender;
        // _spendAllowance(from, spender, amount); // allowance was disabled
        _transfer(from, to, amount);
        return true;
    }
}

// We are using an external testing methodology
contract EchidnaTemplate {
    Staker stakerContract;
    MockERC20 tokenToStake;

    // setup
    constructor() {
        tokenToStake = new MockERC20("Token", "TOK");
        stakerContract = new Staker(address(tokenToStake));
        // Pre-load our balance
        tokenToStake.mint(address(this), type(uint128).max);
    }

    // Instead of preloading the balance, we can write a testMint function to help Echidna figure out to mint tokens while testing other function-level invariants
    // function testMint(address _to, uint256 _amount) {
    //     tokenToStake.mint(_to, _amount);
    // }

    // function-level invariants
    function testStake(uint256 _amount) public {
        // Pre-condition
        require(tokenToStake.balanceOf(address(this)) > 0);
        // Optimization: amount is now bounded between [1, balanceOf(address(this))]
        // Becuase it would fail if trying to .transferFrom more than what this address holds, which would be wasted computation
        uint256 amount = 1 +
            (_amount % (tokenToStake.balanceOf(address(this))));
        // State before the "action"
        uint256 preStakedBalance = stakerContract.stakedBalances(address(this));
        // Action - use a try/catch to test both happy and unhappy paths
        try stakerContract.stake(amount) returns (uint256 stakedAmount) {
            // Post-condition
            // Make sure my staked balance increased in the happy path
            assert(
                stakerContract.stakedBalances(address(this)) ==
                    preStakedBalance + stakedAmount
            );
            // Also another post-condition, the balance of the contract should increase also..
        } catch (bytes memory err) {
            // Post-condition
            // Unhappy path - we assume to believe that calling .stake() will never fail, so we simply assert(false)
            assert(false);
        }
    }

    function testUnstake(uint256 _stakedAmount) public {
        // Pre-condition, we know we need to stake before unstaking, so using this pre-condition with stateful testing
        require(stakerContract.stakedBalances(address(this)) > 0);
        // Optimization: amount is now bounded between [1, stakedBalance[address(this)]]
        // Because unstaking more than the address has would fail and cause wasted computation to occur
        uint256 stakedAmount = 1 +
            (_stakedAmount % (stakerContract.stakedBalances(address(this))));
        // State before the "action"
        uint256 preTokenBalance = tokenToStake.balanceOf(address(this));
        // Action
        uint256 amount = stakerContract.unstake(stakedAmount);
        // Post-condition
        assert(
            tokenToStake.balanceOf(address(this)) == preTokenBalance + amount
        );
    }
}
