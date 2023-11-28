import Navbar from "./Navbar";
import NFTTile from "./NFTTile";
import MarketplaceJSON from "../Marketplace.json";
import axios from "axios";
import { useState } from "react";
import { GetIpfsUrlFromPinata } from "../utils";

export default function Marketplace() {
const sampleData = [
    {
        "name": "art1",
        "description": "magicwem",
        "website":"https://images.app.goo.gl/dpMHVGiiJd1is9p48",
        "image":"https://gateway.pinata.cloud/ipfs/QmQQ15sbrBCdpaFFimiyaLj9rEVCVDQiddP3V9L5HsxqNP",
        "price":"0.03ETH",
        "currentlySelling":"True",
        "address":"0x05498b82DBAC5Dc764d8CBE25bB658E683d68283",
    },
    {
        "name": "art2",
        "description": "eye",
        "website":"https://images.app.goo.gl/FDR3NzQk6vHzZmQP7",
        "image":"https://gateway.pinata.cloud/ipfs/QmZmJKbmdJv7i3qWoNsAiAsvgALPmPR7wHFPQoGEJW4vq3",
        "price":"0.023ETH",
        "currentlySelling":"True",
        "address":"0x05498b82DBAC5Dc764d8CBE25bB658E683d68283",
    },
    {
        "name": "art3",
        "description": "provincez",
        "website":"http://axieinfinity.io",
        "image":"https://gateway.pinata.cloud/ipfs/QmYH9PBHtpYy1173DwpCQunzTqo8V6d2G5ByaLPRpwzqWY",
        "price":"0.03ETH",
        "currentlySelling":"True",
        "address":"0x05498b82DBAC5Dc764d8CBE25bB658E683d68283",
    },
];
const [data, updateData] = useState(sampleData);
const [dataFetched, updateFetched] = useState(false);

async function getAllNFTs() {
    const ethers = require("ethers");
    
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
   
    let contract = new ethers.Contract(MarketplaceJSON.address, MarketplaceJSON.abi, signer)
    
    let transaction = await contract.getAllNFTs()

  
    const items = await Promise.all(transaction.map(async i => {
        var tokenURI = await contract.tokenURI(i.tokenId);
        console.log("getting this tokenUri", tokenURI);
        tokenURI = GetIpfsUrlFromPinata(tokenURI);
        let meta = await axios.get(tokenURI);
        meta = meta.data;

        let price = ethers.utils.formatUnits(i.price.toString(), 'ether');
        let item = {
            price,
            tokenId: i.tokenId.toNumber(),
            seller: i.seller,
            owner: i.owner,
            image: meta.image,
            name: meta.name,
            description: meta.description,
        }
        return item;
    }))

    updateFetched(true);
    updateData(items);
}

if(!dataFetched)
    getAllNFTs();

return (
    <div>
        <Navbar></Navbar>
        <div className="flex flex-col place-items-center mt-20">
            <div className="md:text-xl font-bold text-white">
                Top NFTs
            </div>
            <div className="flex mt-5 justify-between flex-wrap max-w-screen-xl text-center">
                {data.map((value, index) => {
                    return <NFTTile data={value} key={index}></NFTTile>;
                })}
            </div>
        </div>            
    </div>
);

}