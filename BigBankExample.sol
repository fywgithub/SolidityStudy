// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

// 导入 Hardhat 的 console.log
import "hardhat/console.sol";

// 定义Bank接口
interface IBank {
    // 设置管理员
    function setAdmin(address _admin) external;
    // 管理员取款
    function adminWithdraw() external payable;
}

// Bank 合约
contract Bank is IBank {

    address private admin; // 管理员
    mapping(address => uint256) public bankInfo; // 存储账户余额
    Depositor [3] public top3;  //存款TOP3
    // 结构体
    struct Depositor {
        address account;
        uint256 money;
    }

    // 构造函数
    constructor(address payable _admin) {
        admin = _admin;
    }

    // 仅admin可以调用
    modifier onlyAdmin() {
        require(admin == msg.sender, "Only administrators can call this function");
        _;
    }

    // 设置管理员
    function setAdmin(address _admin) public onlyAdmin {
        admin = _admin;
    }

    // 管理员取款
    function adminWithdraw() public payable onlyAdmin {
        // console.log("admin:", admin);
        // console.log("sender:", msg.sender);
        // console.log("origin:", tx.origin);

        uint256 amount = address(this).balance;
        require(amount > 0, "The balance must be greater than 0");  // 余额必须大于0
        payable(admin).transfer(amount);
    }

    // 合约存款
    receive() external payable virtual {
        updateInfo(); // 更新存款信息
    }

    // 更新存款信息
    function updateInfo() internal {
        if (bankInfo[msg.sender] == 0) {
            bankInfo[msg.sender] = msg.value;
        } else {
            bankInfo[msg.sender] += msg.value;
        }

         // 如果金额小于第三名且前三名都已满，则直接返回
        if (bankInfo[msg.sender] <= top3[2].money && top3[2].account != address(0)) {
            return;
        }
        // 查找插入位置
        int8 insertPosition = -1;
        for (uint8 i = 0; i < 3; i++) {
            if (bankInfo[msg.sender] > top3[i].money || top3[i].account == address(0)) {
                insertPosition = int8(i);
                break;
            }
        }
        // 如果找到插入位置
        if (insertPosition >= 0) {
            // 向后移动元素
            for (uint8 j = 2; j > uint8(insertPosition); j--) {
                top3[j] = top3[j - 1];
            }
            // 插入新记录
            top3[uint8(insertPosition)] = Depositor(msg.sender, bankInfo[msg.sender]);
        }
    }
}

// BigBank 合约
contract BigBank is Bank {

    // 构造函数继承
    constructor(address payable _admin) Bank(_admin) {}

    // 仅 >0.001 ether(用 modifier 权限控制)可以存款
    modifier onlyOverMinDeposit() {
        require(msg.value > 0.001 ether, "The deposit cannot be less than 0.001 ether");
        _;
    }

    // 重写 receive()
    receive() external payable override onlyOverMinDeposit {
        super.updateInfo();
    }
}

// Admin 合约
contract Admin {
    IBank public bank; // Bank 合约

    // 构造函数 设置合约地址是Bank还是BigBank
    constructor(address bankAddress) {
        bank = IBank(bankAddress);
    }
    
    /**
     * 前提: 先将 BigBank 的管理员转移给 Admin 合约
     * 调用 BigBank 合约的 withdraw()
     */
    function withdraw() external {
        bank.adminWithdraw();
    }

    // 合约存款
    receive() external payable{}
}
