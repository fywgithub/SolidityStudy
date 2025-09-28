// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 导入 Hardhat 的 console.log
import "hardhat/console.sol";

// ERC20 合约
contract BaseERC20 {
    string public name; // 代币的名称
    string public symbol;   // 代币的简写或缩写
    uint8 public decimals;  // 代币的小数位数

    uint256 public totalSupply; // 代币的总发行量

    mapping (address => uint256) balances; // 代币余额存储

    mapping (address => mapping (address => uint256)) allowances; // 批准消费Token

    event Transfer(address indexed from, address indexed to, uint256 value);    // 在代币被转移时触发。
    event Approval(address indexed owner, address indexed spender, uint256 value);  // 在调用 approve 方法时触发。

    // 构造函数，初始化代币的名称、符号、小数位数和总供应量
    constructor() {
        // 1、设置 Token 名称（name）："BaseERC20"
        name = "BaseERC20"; 
        // 2、设置 Token 符号（symbol）："BERC20"
        symbol = "BERC20"; 
        // 3、设置 Token 小数位decimals：18
        decimals = 18; 
        // 4、设置 Token 总量（totalSupply）:100,000,000
        totalSupply = 100000000 * 10 ** uint256(decimals);

        // 创建者发放66个
        balances[msg.sender] = 66 * 10 ** uint256(decimals);  
    }

    // 5、返回特定地址(_owner)的代币余额
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];    
    }

    // 6、允许 Token 的所有者将他们的 Token 发送给任何人（transfer）；转帐超出余额时抛出异常(require),并显示错误消息 “ERC20: transfer amount exceeds balance”。
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "ERC20: transfer amount exceeds balance");

        balances[msg.sender] -= _value;    
        balances[_to] += _value;   

        emit Transfer(msg.sender, _to, _value);  
        return true;   
    }

    // 7、允许 Token 的所有者批准某个地址消费他们的一部分Token（approve）
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowances[msg.sender][_spender] = _value; 
        emit Approval(msg.sender, _spender, _value); 
        return true; 
    }

    // 8、允许任何人查看一个地址可以从其它账户中转账的代币数量（allowance）
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }

    // 9、允许被授权的地址消费他们被授权的 Token 数量（transferFrom）；
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // 转帐超出余额时抛出异常(require)，异常信息：“ERC20: transfer amount exceeds balance”
        require(balances[_from] >= _value, "ERC20: transfer amount exceeds balance");
        // 转帐超出授权数量时抛出异常(require)，异常消息：“ERC20: transfer amount exceeds allowance”。
        require(allowances[_from][msg.sender] >= _value,"ERC20: transfer amount exceeds allowance");

        balances[_from] -= _value; 
        balances[_to] += _value; 

        allowances[_from][msg.sender] -= _value;
        
        emit Transfer(_from, _to, _value); 
        return true; 
    }
}

// TokenBank 合约
contract TokenBank {

    mapping(address => mapping(address => uint256)) public balances; // 存储账户余额

    event TokensDeposited(address indexed user, address indexed token, uint256 amount); // 存款事件
    event TokensWithdrawn(address indexed user, address indexed token, uint256 amount); // 取款事件

    // 存款
    function deposit(address payable tokenAddress, uint256 amount) public payable returns (bool) {
        require(tokenAddress != address(0), "Invalid token address");
        require(amount > 0, "Amount must be greater than 0");

        BaseERC20 token = BaseERC20(tokenAddress);
        // 首先用户需要授权给合约
        // 检查授权额度
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Insufficient allowance");
        
        // 从用户转账到合约
        token.transferFrom(msg.sender, address(this), amount);
        // 更新余额
        balances[msg.sender][tokenAddress] += amount;
        
        emit TokensDeposited(msg.sender, tokenAddress, amount);
        return true;
    }

    // 取款
    function withdraw(address payable tokenAddress, uint256 amount) public payable returns (bool) {
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender][tokenAddress] >= amount, "Insufficient balance");
        
        // 更新余额
        balances[msg.sender][tokenAddress] -= amount;
        // 转账给用户
        BaseERC20(tokenAddress).transfer(msg.sender, amount);
        
        emit TokensWithdrawn(msg.sender, tokenAddress, amount);
        return true;
    }

}
