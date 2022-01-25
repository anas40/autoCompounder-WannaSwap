// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IWannaFarm {
    function deposit(
        uint256 _pid,
        uint256 _amount,
        address _ref
    ) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function userInfo(uint256 _pid, address _user)
        external
        view
        returns (uint256, uint256);
}

interface IWannaRouterV2 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );
}

contract WannaCompounder {
    address public ownerAddress;

    address public wannaFarmAddress =
        0x2B2e72C232685fC4D350Eaa92f39f6f8AD2e1593;
    address public wannaRouterV2Address =
        0xa3a1eF5Ae6561572023363862e238aFA84C72ef5;

    address public wannaTokenAddress =
        0x7faA64Faf54750a2E3eE621166635fEAF406Ab22;
    address public auroraTokenAddress =
        0x8BEc47865aDe3B172A928df8f990Bc7f2A3b9f79;
    address public wnearTokenAddress =
        0xC42C30aC6Cc15faC9bD938618BcaA1a1FaE8501d;
    address public wnearAuroraLPTokenAddress =
        0x7E9EA10E5984a09D19D05F31ca3cB65BB7df359d;


    //path for farm reward to lp pair swap
    address[] public wannaAuroraPath;
    address[] public wannaWnearPath;

    IWannaFarm wannaFarmContract = IWannaFarm(wannaFarmAddress);
    IWannaRouterV2 wannaRouterV2Contract = IWannaRouterV2(wannaRouterV2Address);

    IERC20 wannaTokenContract = IERC20(wannaTokenAddress);
    IERC20 nearAuroraLPTokenContract = IERC20(wnearAuroraLPTokenAddress);
    IERC20 auroraTokenContract = IERC20(auroraTokenAddress);
    IERC20 wnearTokenContract = IERC20(wnearTokenAddress);

    constructor(
        address[] memory _wannaAuroraPath,
        address[] memory _wannaWnearPath
    ) {
        ownerAddress = msg.sender;

        setWannaAuroraPath(_wannaAuroraPath);
        setWannaWnearPath(_wannaWnearPath);

        _approve(auroraTokenContract, wannaRouterV2Address);
        _approve(wnearTokenContract, wannaRouterV2Address);
        _approve(nearAuroraLPTokenContract, wannaFarmAddress);
        _approve(wannaTokenContract, wannaRouterV2Address);
    }

    modifier onlyOwner() {
        require(msg.sender == ownerAddress, "Limited for owner");
        _;
    }

    //swap the wanna token for any token using the given path
    function _swap(uint256 _balance, address[] memory _path) internal {
        uint256[] memory tokenPathOutput = wannaRouterV2Contract.getAmountsOut(
            _balance,
            _path
        );

        wannaRouterV2Contract.swapExactTokensForTokens(
            _balance,
            tokenPathOutput[tokenPathOutput.length - 1],
            _path,
            address(this),
            block.timestamp + 20 minutes
        );
    }

    //swaps the assets using v2 router and adds them as liquidity
    function _compound() internal {
        //wanna token balance
        uint256 wannaBalance = wannaTokenContract.balanceOf(address(this));

        _swap(wannaBalance / 2, wannaAuroraPath);
        _swap(wannaBalance - (wannaBalance / 2), wannaWnearPath);

        wannaRouterV2Contract.addLiquidity(
            auroraTokenAddress,
            wnearTokenAddress,
            auroraTokenContract.balanceOf(address(this)),
            wnearTokenContract.balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp + 20 minutes
        );

        depositLPtoFarm();
    }

    //utility funciton to approve any address maximum possible amount
    function _approve(IERC20 _contract, address _recipient) internal onlyOwner {
        unchecked {
            _contract.approve(_recipient, uint256(0) - 1);
        }
    }

    //utility funciton to withdraw erc20 tokens to owner account
    function _withdrawERC20Token(address _token) internal onlyOwner {
        IERC20 token = IERC20(_token);
        token.transfer(ownerAddress, token.balanceOf(address(this)));
    }

    //change the owner
    function transferOwnership(address _newOwner) public onlyOwner {
        ownerAddress = _newOwner;
    }

    //used to set the router path for wanna to aurora swap
    function setWannaAuroraPath(address[] memory _path) public onlyOwner {
        wannaAuroraPath = _path;
    }

    //used to set the router path for wanna to wnear swap
    function setWannaWnearPath(address[] memory _path) public onlyOwner {
        wannaWnearPath = _path;
    }

    //harvest farm reward and componds
    function harvestAndCompound() external {
        //harvesting the wanna token
        wannaFarmContract.deposit(8, 0, address(0));
        _compound();
    }

    //used to deposit lp token from account to this contract
    function depositLP(uint256 _amount) public {
        nearAuroraLPTokenContract.transferFrom(
            msg.sender,
            address(this),
            _amount
        );
    }

    //used to deposit lp token from this contract to farm contract
    function depositLPtoFarm() public {
        //getting the lp amount in the contract
        uint256 lpAmount = nearAuroraLPTokenContract.balanceOf(address(this));

        // depositing the lp into the farm contract
        wannaFarmContract.deposit(8, lpAmount, address(0x0));
    }

    //used to withdraw lp token from farm contract to this contract
    function withdrawLPfromFarm() public onlyOwner {
        // amout of lp
        (uint256 balance, ) = wannaFarmContract.userInfo(8, address(this));

        //withdrawing the lp from farm to contract
        wannaFarmContract.withdraw(8, balance);
    }

    //withdraw lp token as well as other erc20 tokens used by this contract
    function withdrawLP() public onlyOwner {
        _withdrawERC20Token(wannaTokenAddress);
        _withdrawERC20Token(auroraTokenAddress);
        _withdrawERC20Token(wnearTokenAddress);
        _withdrawERC20Token(wnearAuroraLPTokenAddress);
    }
}
