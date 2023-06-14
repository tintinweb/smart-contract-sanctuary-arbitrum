// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

error InsufficientAmount(uint256 required);
error WithdrawalFailed();
error NotFound();
error Forbidden();
error Unauthorized();

/**
@title Smart Contract for OnchainCareers Job Board
@author SkiX (@skix123)
@notice Visit https://onchain.careers
*/
contract OnchainCareers {
    struct JobPostInput {
        uint256 companyIndex;
        bytes32 companyName;
        bytes32 title;
        bytes32 applicationUrl;
        bytes32 locationGeo;
        uint256 salaryMin;
        uint256 salaryMax;
        uint256 salaryCurrency;
        uint256 salaryFrequency;
        uint256 locationMode;
        uint256 flags;
        uint256[] techStack;
        uint256[] employmentTypes;
        string description;
    }

    struct RecruiterInput {
        bytes32 name;
        bytes32 website;
        bytes32 avatar;
        bytes32 linkedIn;
        bytes32 twitter;
        bytes32 discord;
        string description;
    }

    struct CompanyInput {
        bytes32 name;
        bytes32 shortDescription;
        bytes32 website;
        bytes32 logo;
        bytes32 twitter;
        bytes32 discord;
        uint256 size;
        string description;
    }

    struct JobPost {
        uint256 companyIndex;
        bytes32 companyName;
        bytes32 title;
        bytes32 applicationUrl;
        bytes32 locationGeo;
        uint256 creationTimestamp;
        uint256 boost;
        uint256 salaryMin;
        uint256 salaryMax;
        uint256 salaryCurrency;
        uint256 salaryFrequency;
        uint256 locationMode;
        uint256 flags;
        uint256[] employmentTypes;
        uint256[] techStack;
        address recruiter;
        string description;
    }

    struct Company {
        bytes32 name;
        bytes32 shortDescription;
        bytes32 website;
        bytes32 logo;
        bytes32 twitter;
        bytes32 discord;
        uint256 size;
        uint256 creationTimestamp;
        uint256 flags;
        string description;
    }

    struct Recruiter {
        bytes32 name;
        bytes32 website;
        bytes32 avatar;
        bytes32 linkedIn;
        bytes32 twitter;
        bytes32 discord;
        uint256 creationTimestamp;
        uint256 flags;
        string description;
    }

    mapping(uint256 => JobPost) private jobPosts;
    mapping(uint256 => Company) private companies;
    mapping(address => Recruiter) private recruiters;
    mapping(uint256 => mapping(address => bool)) public isCompanyAdmin;
    mapping(uint256 => mapping(address => bool)) public isCompanyRecruiter;
    address private owner;
    uint256 private totalJobPosts;
    uint256 private totalCompanies;

    /**
     * @notice Stores the prices (in wei) for different features.
     * @dev An array of uint256 values:
     * 		0 - job post base price
     * 		1 - job post featured price
     * 		2 - job post extended expiration time
     * 		3, 4, 5 - job post custom features (not in use in the time of creating the contract, might be used in the future)
     * 		6 - job post minimal boost amount
     * 		7 - company profile base price
     * 		8, 9, 10 - company profile custom features (not in use in the time of creating the contract, might be used in the future)
     * 		11 - recruiter profile base price
     * 		12, 13, 14 - recruiter profile custom features (not in use in the time of creating the contract, might be used in the future)
     */
    uint256[15] public pricing;

    event JobPostAdded(uint256 indexed index);
    event JobPostBoosted(uint256 indexed index, uint256 amount);
    event JobPostCompanyUpdated(uint256 indexed jobPostIndex, uint256 indexed companyIndex);
    event JobPostRemoved(uint256 indexed index);
    event CompanyProfileAdded(uint256 indexed index);
    event CompanyProfileUpdated(uint256 indexed index);
    event CompanyProfileRemoved(uint256 indexed index);
    event RecruiterProfileAdded(address indexed addr);
    event RecruiterProfileUpdated(address indexed addr);
    event RecruiterProfileRemoved(address indexed addr);
    event CompanyAdminAdded(uint256 indexed companyIndex, address indexed admin);
    event CompanyAdminRemoved(uint256 indexed companyIndex, address indexed admin);
    event CompanyRecruiterAdded(uint256 indexed companyIndex, address indexed recruiter);
    event CompanyRecruiterRemoved(uint256 indexed companyIndex, address indexed recruiter);
    event CompanyProfileVerificationStatusUpdated(uint256 indexed companyIndex, bool isVerified);
    event RecruiterProfileVerificationStatusUpdated(address indexed recruiter, bool isVerified);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Ping();

    constructor() {
        owner = msg.sender;
        pricing[0] = 1e16;
        pricing[1] = 1e17;
        pricing[2] = 5e16;
        pricing[6] = 1e16;
        pricing[7] = 1e17;
        pricing[11] = 1e17;
        ++totalCompanies; // index zero is used as empty company profile
    }

    /**
     * @notice Retrieves the boolean value at the specified position from a packed booleans value.
     * @dev This is a private helper function.
     * @param packedBools The uint256 containing the packed booleans.
     * @param position The position of the target boolean value within the packed storage.
     * @return bool The boolean value at the specified position.
     */
    function _getBoolean(uint256 packedBools, uint256 position) private pure returns (bool) {
        return (packedBools >> position) & uint256(1) == 1;
    }

    /**
     * @notice Sets the boolean value at the specified position within a uint256 containing packed booleans.
     * @dev This is a private helper function.
     * @param packedBools The uint256 containing the packed booleans.
     * @param position The position of the target boolean value within the packed storage.
     * @param isTrue The boolean value to be set at the specified position.
     * @return uint256 The updated uint256 containing the packed boolean values.
     */
    function _setBoolean(uint256 packedBools, uint256 position, bool isTrue) private pure returns (uint256) {
        if (isTrue) return packedBools | (uint256(1) << position);
        return packedBools & ~(uint256(1) << position);
    }

    /**
     * @notice Calculates the job post cost based on selected properties (flags).
     * @dev This is a private function.
     * @param flags The uint256 containing the packed booleans.
     * @return uint256 Total cost in wei.
     */
    function _calculateJobPostCost(uint256 flags) private view returns (uint256) {
        uint256 cost = pricing[0];

        if (_getBoolean(flags, 0)) {
            // if featured
            unchecked {
                cost += pricing[1];
            }
        }

        if (_getBoolean(flags, 1)) {
            // if extended expiration
            unchecked {
                cost += pricing[2];
            }
        }

        // custom flags
        if (_getBoolean(flags, 2)) {
            unchecked {
                cost += pricing[3];
            }
        }

        if (_getBoolean(flags, 3)) {
            unchecked {
                cost += pricing[4];
            }
        }

        if (_getBoolean(flags, 4)) {
            unchecked {
                cost += pricing[5];
            }
        }

        return cost;
    }

    /**
     * @notice Adds a company admin by the given company index.
     * @dev This is a private function.
     * 		Emits a `CompanyAdminAdded` event.
     * @param index The index of the company profile to which the admin is being added.
     * @param addr The address of the admin to be added.
     */
    function _addCompanyAdmin(uint256 index, address addr) private {
        isCompanyAdmin[index][addr] = true;

        emit CompanyAdminAdded(index, addr);
    }

    /**
     * @notice Removes a company admin by the given index.
     * @dev This is a private function.
     * 		Emits a `CompanyAdminRemoved` event.
     * @param index The index of the company profile from which the admin is being removed.
     * @param addr The address of the admin to be removed.
     */
    function _removeCompanyAdmin(uint256 index, address addr) private {
        isCompanyAdmin[index][addr] = false;

        emit CompanyAdminRemoved(index, addr);
    }

    /**
     * @notice Removes a company recruiter by the given index.
     * @dev This is a private function.
     * 		Emits a `CompanyRecruiterRemoved` event.
     * @param index The index of the company profile from which the recruiter is being removed.
     * @param addr The address of the recruiter to be removed.
     */
    function _removeCompanyRecruiter(uint256 index, address addr) private {
        isCompanyRecruiter[index][addr] = false;

        emit CompanyRecruiterRemoved(index, addr);
    }

    /**
     * @notice Creates a new job post with the provided input data.
     *		Requirements:
     * 		- The job post must have at least one tech stack and employment type.
     * 		- If the job post is associated with a company, the caller must be a company recruiter or an admin.
     * 		- The caller must send the required amount to cover the job post cost.
     * @dev Adds a job post to the `jobPosts` mapping.
     * 		Emits a `JobPostAdded` event.
     * 		Transaction reverts with "Forbidden" if the job post does not have at least one tech stack or employment type.
     * 		Transaction reverts with "Unauthorized" if the job post is associated with a company and the caller is neither a company recruiter nor an admin.
     * 		Transaction reverts with "InsufficientAmount" if the amount sent is less than the required job post cost.
     * @param jobPostInput A `JobPostInput` struct containing the job post data.
     */
    function addJobPost(JobPostInput calldata jobPostInput) external payable {
        if (jobPostInput.techStack.length == 0) revert Forbidden();
        if (jobPostInput.employmentTypes.length == 0) revert Forbidden();

        bytes32 companyName = jobPostInput.companyName;

        if (jobPostInput.companyIndex > 0) {
            if (!isCompanyRecruiter[jobPostInput.companyIndex][msg.sender] && !isCompanyAdmin[jobPostInput.companyIndex][msg.sender])
                revert Unauthorized();

            Company memory company = companies[jobPostInput.companyIndex];
            if (company.creationTimestamp == 0) revert Unauthorized();

            companyName = company.name;
        }

        uint256 cost = _calculateJobPostCost(jobPostInput.flags);
        if (msg.value < cost) revert InsufficientAmount({required: cost});

        uint256 boost;
        unchecked {
            boost = msg.value - cost;
        }

        uint256 jobPostIndex = totalJobPosts;
        jobPosts[jobPostIndex] = JobPost({
            recruiter: msg.sender,
            companyIndex: jobPostInput.companyIndex,
            companyName: companyName,
            title: jobPostInput.title,
            description: jobPostInput.description,
            creationTimestamp: block.timestamp,
            techStack: jobPostInput.techStack,
            salaryMin: jobPostInput.salaryMin,
            salaryMax: jobPostInput.salaryMax,
            salaryCurrency: jobPostInput.salaryCurrency,
            salaryFrequency: jobPostInput.salaryFrequency,
            employmentTypes: jobPostInput.employmentTypes,
            locationMode: jobPostInput.locationMode,
            locationGeo: jobPostInput.locationGeo,
            flags: jobPostInput.flags,
            applicationUrl: jobPostInput.applicationUrl,
            boost: boost
        });

        unchecked {
            ++totalJobPosts;
        }

        emit JobPostAdded(jobPostIndex);
    }

    /**
     * @notice Boosts a job post by the given index.
     * 		Requirements:
     * 		- The caller must send required amount (defined in `pricing[6]`) to boost the job post.
     * @dev Increases the boost value of the job post by the amount sent.
	 		Emits a `JobPostBoosted` event.
     * 		Transaction reverts with "InsufficientAmount" if the amount sent is less than required.
     * @param index The index of the job post to be boosted.
     */
    function boostJobPost(uint256 index) external payable {
        uint256 minAmount = pricing[6];
        if (msg.value < minAmount) revert InsufficientAmount({required: minAmount});

        unchecked {
            jobPosts[index].boost += msg.value;
        }

        emit JobPostBoosted(index, msg.value);
    }

    /**
     * @notice Updates the company profile associated with a job post by the given job post index.
     * 		Requirements:
     * 		- The company must exist.
     * 		- The caller must be the job post's creator.
     * 		- The caller must be a company recruiter or a company admin.
     * @dev Emits a `JobPostCompanyUpdated` event.
     *		Transaction reverts with "Forbidden" if the company is empty.
     * 		Transaction reverts with "NotFound" if the company does not exist.
     * 		Transaction reverts with "Unauthorized" if the caller is neither the job post's creator, a company recruiter, nor a company admin.
     * @param jobPostIndex The index of the job post for which the company is being updated.
     * @param companyIndex The index of the company profile to be associated with the job post.
     */
    function updateJobPostCompany(uint256 jobPostIndex, uint256 companyIndex) external {
        if (companyIndex == 0) revert Forbidden();
        if (companies[companyIndex].creationTimestamp == 0) revert NotFound();
        if (!isCompanyRecruiter[companyIndex][msg.sender] && !isCompanyAdmin[companyIndex][msg.sender]) revert Unauthorized();

        JobPost storage jobPost = jobPosts[jobPostIndex];
        if (jobPost.recruiter != msg.sender) revert Unauthorized();

        jobPost.companyIndex = companyIndex;

        emit JobPostCompanyUpdated(jobPostIndex, companyIndex);
    }

    /**
     * @notice Retrieves a job post by the given index.
     * @dev If there's no job post at the given index, the returned object has creationTimestamp of 0.
     * @param index The index of the job post to be retrieved.
     * @return JobPost memory The job post associated with the given index.
     */
    function getJobPost(uint256 index) external view returns (JobPost memory) {
        return jobPosts[index];
    }

    /**
     * @notice Removes a job post by the given index.
     * 		Requirements:
     *		- The job post must exist.
     *		- Can only be called by the job post's creator, a company recruiter, or a company admin.
     * @dev Emits a `JobPostRemoved` event.
     * 		Transaction reverts with "NotFound" if the job post does not exist.
     * 		Transaction reverts with "Unauthorized" if the caller is not the job post's creator, a company recruiter, or a company admin.
     * @param index The index of the job post to be removed.
     */
    function removeJobPost(uint256 index) external {
        JobPost storage jobPost = jobPosts[index];
        if (jobPost.creationTimestamp == 0) revert NotFound();

        if (jobPost.companyIndex == 0) {
            if (jobPost.recruiter != msg.sender) revert Unauthorized();
        } else {
            if (
                jobPost.recruiter != msg.sender &&
                !isCompanyRecruiter[jobPost.companyIndex][msg.sender] &&
                !isCompanyAdmin[jobPost.companyIndex][msg.sender]
            ) revert Unauthorized();
        }

        delete jobPosts[index];

        emit JobPostRemoved(index);
    }

    /**
     * @notice Creates a new company profile and associates it with the caller's address as an admin.
     * 		Requirements:
     * 		- The caller must send required amount (defined in `pricing[7]`).
     * @dev Emits a `CompanyProfileAdded` event.
     * 		Transaction reverts with "InsufficientAmount" if not enough amount is sent.
     * @param companyInput A `CompanyInput` struct containing the profile data.
     */
    function addCompanyProfile(CompanyInput calldata companyInput) external payable {
        uint256 minAmount = pricing[7];
        if (msg.value < minAmount) revert InsufficientAmount({required: minAmount});

        uint256 companyIndex = totalCompanies;
        companies[companyIndex] = Company({
            name: companyInput.name,
            shortDescription: companyInput.shortDescription,
            website: companyInput.website,
            logo: companyInput.logo,
            twitter: companyInput.twitter,
            discord: companyInput.discord,
            size: companyInput.size,
            creationTimestamp: block.timestamp,
            flags: 0,
            description: companyInput.description
        });
        unchecked {
            ++totalCompanies;
        }

        emit CompanyProfileAdded(companyIndex);

        _addCompanyAdmin(companyIndex, msg.sender);
    }

    /**
     * @notice Updates a company profile by the given index.
     * 		Requirements:
     * 		- The caller must be a company admin.
     * 		- The company must exist.
     * @dev Emits a `CompanyProfileUpdated` event.
     * 		Transaction reverts with "Unauthorized" if the caller is not a company admin.
     *		Transaction reverts with "NotFound" if the company does not exist.
     * @param index The index of the company profile to be updated.
     * @param companyInput A `CompanyInput` struct containing the updated profile data.
     */
    function updateCompanyProfile(uint256 index, CompanyInput calldata companyInput) external {
        if (!isCompanyAdmin[index][msg.sender]) revert Unauthorized();

        Company storage company = companies[index];
        if (company.creationTimestamp == 0) revert NotFound();

        company.name = companyInput.name;
        company.shortDescription = companyInput.shortDescription;
        company.website = companyInput.website;
        company.logo = companyInput.logo;
        company.twitter = companyInput.twitter;
        company.discord = companyInput.discord;
        company.size = companyInput.size;
        company.description = companyInput.description;

        emit CompanyProfileUpdated(index);
    }

    /**
     * @notice Retrieves a company profile by the given index.
     * @dev If the given index does not have a company profile, the returned profile has a creationTimestamp of 0.
     * @param index The index of the company profile to be retrieved.
     * @return Company The company profile associated with the given index.
     */
    function getCompanyProfile(uint256 index) external view returns (Company memory) {
        return companies[index];
    }

    /**
     * @notice Removes a company profile by the given index.
     * 		Requirements:
     * 		- The caller must be a company admin.
     * 		- The company must exist.
     * @dev Emits a `CompanyAdminRemoved` event.
     * 		Emits a `CompanyRecruiterRemoved` event.
     * 		Emits a `CompanyProfileRemoved` event.
     *		Transaction reverts with "Unauthorized" if the caller is not a company admin.
     *		Transaction reverts with "NotFound" if the company does not exist.
     * @param index The index of the company profile to be removed.
     */
    function removeCompanyProfile(uint256 index) external {
        if (!isCompanyAdmin[index][msg.sender]) revert Unauthorized();
        if (companies[index].creationTimestamp == 0) revert NotFound();

        delete companies[index];
        _removeCompanyAdmin(index, msg.sender);
        _removeCompanyRecruiter(index, msg.sender);

        emit CompanyProfileRemoved(index);
    }

    /**
     * @notice Adds a company admin by the given index.
     * 		Requirements:
     * 		- The caller must be an existing company admin.
     * 		- The company must exist.
     * @dev Emits a `CompanyAdminAdded` event.
     * 		Transaction reverts with "Unauthorized" if the caller is not an existing company admin.
     * 		Transaction reverts with "NotFound" if the company does not exist.
     * @param index The index of the company to which the admin is being added.
     * @param addr The address of the admin to be added.
     */
    function addCompanyAdmin(uint256 index, address addr) external {
        if (!isCompanyAdmin[index][msg.sender]) revert Unauthorized();
        if (companies[index].creationTimestamp == 0) revert NotFound();

        _addCompanyAdmin(index, addr);
    }

    /**
     * @notice Removes a company admin by the given index.
     * 		Requirements:
     * 		- The caller must not be the admin being removed.
     * 		- The caller must be another company admin.
     * @dev Emits a `CompanyAdminRemoved` event.
     *		Transaction reverts with "Forbidden" if the caller is the admin being removed.
     *		Transaction reverts with "Unauthorized" if the caller is not another company admin.
     * @param index The index of the company from which the admin is being removed.
     * @param addr The address of the admin to be removed.
     */
    function removeCompanyAdmin(uint256 index, address addr) external {
        if (addr == msg.sender) revert Forbidden();
        if (!isCompanyAdmin[index][msg.sender]) revert Unauthorized();

        _removeCompanyAdmin(index, addr);
    }

    /**
     * @notice Adds a recruiter to a company profile by the given index.
     * 		Requirements:
     * 		- The caller must be a company admin.
     * 		- The company must exist.
     * @dev Emits a `CompanyRecruiterAdded` event.
     * 		Transaction reverts with "Unauthorized" if the caller is not a company admin.
     *		Transaction reverts with "NotFound" if the company does not exist.
     * @param index The index of the company to which the recruiter is being added.
     * @param addr The address of the recruiter to be added.
     */
    function addCompanyRecruiter(uint256 index, address addr) external {
        if (!isCompanyAdmin[index][msg.sender]) revert Unauthorized();
        if (companies[index].creationTimestamp == 0) revert NotFound();

        isCompanyRecruiter[index][addr] = true;

        emit CompanyRecruiterAdded(index, addr);
    }

    /**
     * @notice Removes a recruiter from a company profile by the given index.
     * 		Requirements:
     * 		- The caller must not be the recruiter being removed.
     * 		- The caller must be a company admin.
     * @dev Emits a `CompanyRecruiterRemoved` event.
     * 		Transaction reverts with "Forbidden" if the caller is the recruiter being removed.
     * 		Transaction reverts with "Unauthorized" if the caller is not a company admin.
     * @param index The index of the company from which the recruiter is being removed.
     * @param addr The address of the recruiter to be removed.
     */
    function removeCompanyRecruiter(uint256 index, address addr) external {
        if (addr == msg.sender) revert Forbidden();
        if (!isCompanyAdmin[index][msg.sender]) revert Unauthorized();

        _removeCompanyRecruiter(index, addr);
    }

    /**
     * @notice Creates a new recruiter profile associated with the caller's address.
     * 		Requirements:
     * 		- The caller must not already have a recruiter profile.
     * 		- The caller must send required amount (defined in `pricing[11]`).
     * @dev Emits a `RecruiterProfileAdded` event.
     * 		Transaction reverts with "InsufficientAmount" if the amount sent is less than required.
     *		Transaction reverts with "Forbidden" if the caller already has a recruiter profile.
     * @param recruiterInput A `RecruiterInput` struct containing the profile data.
     */
    function addRecruiterProfile(RecruiterInput calldata recruiterInput) external payable {
        uint256 minAmount = pricing[11];
        if (msg.value < minAmount) revert InsufficientAmount({required: minAmount});
        if (recruiters[msg.sender].creationTimestamp > 0) revert Forbidden();

        recruiters[msg.sender] = Recruiter({
            name: recruiterInput.name,
            description: recruiterInput.description,
            website: recruiterInput.website,
            avatar: recruiterInput.avatar,
            linkedIn: recruiterInput.linkedIn,
            twitter: recruiterInput.twitter,
            discord: recruiterInput.discord,
            creationTimestamp: block.timestamp,
            flags: 0
        });

        emit RecruiterProfileAdded(msg.sender);
    }

    /**
     * @notice Updates the recruiter profile associated with the caller's address.
     * 		Requirements:
     * 		- The caller must have a recruiter profile.
     * @dev Emits a `RecruiterProfileUpdated` event.
     * 		Transaction reverts with "NotFound" if the caller does not have a recruiter profile.
     * @param recruiterInput A `RecruiterInput` struct containing the updated profile data.
     */
    function updateRecruiterProfile(RecruiterInput calldata recruiterInput) external {
        Recruiter storage recruiter = recruiters[msg.sender];
        if (recruiter.creationTimestamp == 0) revert NotFound();

        recruiter.name = recruiterInput.name;
        recruiter.description = recruiterInput.description;
        recruiter.website = recruiterInput.website;
        recruiter.avatar = recruiterInput.avatar;
        recruiter.linkedIn = recruiterInput.linkedIn;
        recruiter.twitter = recruiterInput.twitter;
        recruiter.discord = recruiterInput.discord;

        emit RecruiterProfileUpdated(msg.sender);
    }

    /**
     * @notice Retrieves a recruiter profile by the given address.
     * @dev If the given address does not have a recruiter profile, the returned profile has a creationTimestamp of 0.
     * @param addr The address of the recruiter whose profile is being requested.
     * @return Recruiter The recruiter profile associated with the given address.
     */
    function getRecruiterProfile(address addr) external view returns (Recruiter memory) {
        return recruiters[addr];
    }

    /**
     * @notice Removes the recruiter profile associated with the caller's address.
     * 		Requirements:
     * 		- The caller must have a recruiter profile.
     * @dev Emits a `RecruiterProfileRemoved` event.
     *		Transaction reverts with "NotFound" if the caller does not have a recruiter profile.
     */
    function removeRecruiterProfile() external {
        if (recruiters[msg.sender].creationTimestamp == 0) revert NotFound();

        delete recruiters[msg.sender];

        emit RecruiterProfileRemoved(msg.sender);
    }

    /**
     * @notice Sets the verification status of a company profile.
     * 		Requirements:
     * 		- The caller must be the contract owner.
     * @dev Emits a `CompanyProfileVerificationStatusUpdated` event.
     *		Transaction reverts with "Unauthorized" if the caller is not the contract owner.
     * @param index The index of the company profile which verification status is being updated.
     * @param isVerified The new verification status (`true` - verified, `false` - unverified).
     */
    function setCompanyVerificationStatus(uint256 index, bool isVerified) external payable {
        if (msg.sender != owner) revert Unauthorized();

        companies[index].flags = _setBoolean(companies[index].flags, 0, isVerified);

        emit CompanyProfileVerificationStatusUpdated(index, isVerified);
    }

    /**
     * @notice Sets the verification status of a recruiter profile.
     * 		Requirements:
     * 		- The caller must be the contract owner.
     * @dev Emits a `RecruiterProfileVerificationStatusUpdated` event.
     *		Transaction reverts with "Unauthorized" if the caller is not the contract owner.
     * @param addr The address of the recruiter whose verification status is being updated.
     * @param isVerified The new verification status (`true` - verified, `false` - unverified).
     */
    function setRecruiterVerificationStatus(address addr, bool isVerified) external payable {
        if (msg.sender != owner) revert Unauthorized();

        recruiters[addr].flags = _setBoolean(recruiters[addr].flags, 0, isVerified);

        emit RecruiterProfileVerificationStatusUpdated(addr, isVerified);
    }

    /**
     * @notice Returns the address of the contract owner.
     */
    function getOwner() external view virtual returns (address) {
        return owner;
    }

    /**
     * @notice Transfers ownership of the contract to another account (`newOwner`).
     * 		Requirements:
     *		- The caller must be the contract owner.
     *		- New owner must not be void address.
     * @dev Emits a `OwnershipTransferred` event.
     *		Transaction reverts with "Forbidden" if new owner is a void address.
     *		Transaction reverts with "Unauthorized" if the caller is not the contract owner.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) external payable {
        if (newOwner == address(0)) revert Forbidden();
        if (msg.sender != owner) revert Unauthorized();

        address previousOwner = owner;
        owner = newOwner;

        emit OwnershipTransferred(previousOwner, newOwner);
    }

    /**
     * @notice Sets new price to one of the pricing items.
     * 		Requirements:
     *		- The caller must be the contract owner.
     * @dev Transaction reverts with "Unauthorized" if the caller is not the contract owner.
     * @param index The index of the pricing item.
     * @param price New price to be set (in wei).
     */
    function updatePricing(uint256 index, uint256 price) external payable {
        if (msg.sender != owner) revert Unauthorized();

        pricing[index] = price;
    }

    /**
     * @notice Withdraws `amount` of wei to the specified address (`receiver`).
     * 		Requirements:
     *		- The caller must be the contract owner.
     * @dev Transaction reverts with "Unauthorized" if the caller is not the contract owner.
     *		Transaction reverts with "WithdrawalFailed" if withdrawal fails.
     * @param receiver The address of account to receive the funds.
     * @param amount The amount of funds to be withdrawn from the contract (in wei).
     */
    function withdraw(address payable receiver, uint256 amount) external payable {
        if (msg.sender != owner) revert Unauthorized();

        (bool success, ) = receiver.call{value: amount}('');
        if (!success) revert WithdrawalFailed();
    }

    /**
     * @notice Emits a `Ping` event.
     * 		Requirements:
     *		- The caller must be the contract owner.
     * @dev Function used for the system health check.
     *		Transaction reverts with "Unauthorized" if the caller is not the contract owner.
     */
    function ping() external payable {
        if (msg.sender != owner) revert Unauthorized();

        emit Ping();
    }
}