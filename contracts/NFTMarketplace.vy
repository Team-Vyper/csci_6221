import "hardhat/console.vy";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTMarketplace(ERC721URIStorage):
    _tokenIds: uint256(Counters.Counter)
    _itemsSold: uint256(Counters.Counter)
    owner: public(address payable)
    listPrice: uint256(wei)

    struct ListedToken:
        tokenId: uint256
        owner: public(address payable)
        seller: public(address payable)
        price: uint256
        currentlyListed: bool

    idToListedToken: public(map(uint256, ListedToken))

    event TokenListedSuccess(
        tokenId: uint256
        owner: address
        seller: address
        price: uint256
        currentlyListed: bool
    )

    @public
    def __init__():
        ERC721URIStorage.__init__(self, "NFTMarketplace", "NFTM")
        self.owner = msg.sender

    @only_owner
    @public
    def updateListPrice(_listPrice: uint256(wei)):
        self.listPrice = _listPrice

    @public
    @view
    def getListPrice() -> uint256(wei):
        return self.listPrice

    @public
    @view
    def getLatestIdToListedToken() -> ListedToken:
        currentTokenId: uint256 = self._tokenIds.current()
        return self.idToListedToken[currentTokenId]

    @public
    @view
    def getListedTokenForId(tokenId: uint256) -> ListedToken:
        return self.idToListedToken[tokenId]

    @public
    @view
    def getCurrentToken() -> uint256:
        return self._tokenIds.current()

    @public
    def createToken(tokenURI: string, price: uint256(wei)) -> uint256:
        self._tokenIds.increment()
        newTokenId: uint256 = self._tokenIds.current()

        self._safeMint(msg.sender, newTokenId)
        self._setTokenURI(newTokenId, tokenURI)

        self.createListedToken(newTokenId, price)

        return newTokenId

    @private
    def createListedToken(tokenId: uint256, price: uint256(wei)):
        require(msg.value == self.listPrice, "Hopefully sending the
correct price")
        require(price > 0, "Make sure the price isn't negative")

        self.idToListedToken[tokenId] = ListedToken(
            tokenId,
            payable(self),
            payable(msg.sender),
            price,
            True
        )

        self._transfer(msg.sender, self, tokenId)
        self.TokenListedSuccess(
            tokenId,
            self,
            msg.sender,
            price,
            True
        )

    @public
    @view
    def getAllNFTs() -> ListedToken[uint256]:
        nftCount: uint256 = self._tokenIds.current()
        tokens: ListedToken[uint256] = [ListedToken() for i in range(nftCount)]
        currentIndex: uint256 = 0
        currentId: uint256

        for i in range(nftCount):
            currentId = i + 1
            currentItem: ListedToken = self.idToListedToken[currentId]
            tokens[currentIndex] = currentItem
            currentIndex += 1

        return tokens

    @public
    @view
    def getMyNFTs() -> ListedToken[uint256]:
        totalItemCount: uint256 = self._tokenIds.current()
        itemCount: uint256 = 0
        currentIndex: uint256 = 0
        currentId: uint256

        for i in range(totalItemCount):
            if self.idToListedToken[i + 1].owner == msg.sender or
self.idToListedToken[i + 1].seller == msg.sender:
                itemCount += 1

        items: ListedToken[uint256] = [ListedToken() for i in range(itemCount)]

        for i in range(totalItemCount):
            if self.idToListedToken[i + 1].owner == msg.sender or
self.idToListedToken[i + 1].seller == msg.sender:
                currentId = i + 1
                currentItem: ListedToken = self.idToListedToken[currentId]
                items[currentIndex] = currentItem
                currentIndex += 1

        return items

    @public
    def executeSale(tokenId: uint256):
        price: uint256 = self.idToListedToken[tokenId].price
        seller: address = self.idToListedToken[tokenId].seller
        require(msg.value == price, "Please submit the asking price in
order to complete the purchase")

        self.idToListedToken[tokenId].currentlyListed = True
        self.idToListedToken[tokenId].seller = payable(msg.sender)
        self._itemsSold.increment()

        self._transfer(self, msg.sender, tokenId)
        self.approve(self, tokenId)

        payable(self.owner).transfer(self.listPrice)
        payable(seller).transfer(msg.value)