//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Payroll {
    // mapping(address=>uint8) public isEmployee;//0-unregisterd , 1- employee, 2- company // 3-employee waiting state //4-employee joined
    mapping(address=>string) public Name;

    struct salaryStruct{
        uint256 amount;
        uint256 time;
        string sender;
    }
    struct CompanyStruct{
        EmployeeStruct[] EmployeeList;
        salaryStruct[] salaryHistory;
    }

    struct EmployeeStruct{
        address wallet;
        uint256 salary;
    }

    struct EMP{
        address wallet;
        uint256 salary;
        string name;
    }

    mapping(address=> CompanyStruct) Company; //for companies
    mapping(address=> salaryStruct[]) public EmployeeHistory; //for employees
    
     function registerUser( string memory name) public {
        Name[msg.sender] = name;
     }

    function addEmployee(uint256 salary, address employee) public{
        Company[msg.sender].EmployeeList.push(EmployeeStruct(employee, salary));
    }

    function changeEmployeeSalary(uint256 newSal, address employee) public{
        // require(isEmployee[msg.sender]==2, "only companies can reject the applications");
        bool found = false;
        uint index;
        uint length = Company[msg.sender].EmployeeList.length;
        for (uint i = 0; i < length ; i++) {
            if (Company[msg.sender].EmployeeList[i].wallet == employee) {
                found = true;
                index = i;
                break;
            }
        }
        require(found, "Employee not found");
        Company[msg.sender].EmployeeList[index].salary = newSal;
    }

    function removeEmployee(address employee) public{
        // require(isEmployee[msg.sender]==2, "only companies can remove employees");
        bool found = false;
        uint index;
        uint length = Company[msg.sender].EmployeeList.length;
        for (uint i = 0; i < length ; i++) {
            if (Company[msg.sender].EmployeeList[i].wallet == employee) {
                found = true;
                index = i;
                break;
            }
        }
        require(found, "Employee not found");
        delete Company[msg.sender].EmployeeList[index];
        Company[msg.sender].EmployeeList[index] = Company[msg.sender].EmployeeList[length - 1];
        Company[msg.sender].EmployeeList.pop();
    }
    
   
    function payEmployees() public payable{
        // require(isEmployee[msg.sender]==2, "only companies can send salary");
        uint256 totalSal = calculateTotalSalary(msg.sender);
        require(msg.value>= totalSal, "please send the right amount");
        uint length = Company[msg.sender].EmployeeList.length;
        for (uint i = 0; i < length ; i++){
            EmployeeStruct memory employee = Company[msg.sender].EmployeeList[i];
            payable(employee.wallet).transfer(employee.salary);
            EmployeeHistory[employee.wallet].push(salaryStruct(employee.salary,block.timestamp, Name[msg.sender]));
        }
        Company[msg.sender].salaryHistory.push(salaryStruct(totalSal, block.timestamp,Name[msg.sender]));
    }
    
    function calculateTotalSalary(address company) public view returns(uint256){
        // require(isEmployee[msg.sender]==2, "only companies can send salary");
        uint256 total;
        uint length = Company[company].EmployeeList.length;
        for (uint i = 0; i < length ; i++){
            EmployeeStruct memory employee = Company[msg.sender].EmployeeList[i];
             total+=employee.salary;
        }
        return total;
    }

    function getEmployeeList(address company) public view returns(EMP[] memory){
        uint length = Company[company].EmployeeList.length;
        EMP[] memory list = new EMP[](length);
        for (uint i = 0; i < length ; i++){
           EmployeeStruct memory employee = Company[company].EmployeeList[i];
            list[i] = EMP(employee.wallet, employee.salary, Name[employee.wallet] );
        }
        return list;
    }
    
    function getCompanyTransactions(address company)public view returns(salaryStruct[] memory) {
        return Company[company].salaryHistory;
    }

    function getEmployeeTransactions(address employee)public view returns(salaryStruct[] memory) {
        return EmployeeHistory[employee];
    }
}