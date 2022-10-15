var Jimp = require('jimp');
const fs = require("fs");

const glob = require("glob");


const pixels = [];
const colors = [];
var getDirectories = function (src, callback) {
  glob(src + '/**/*', callback);
};
getDirectories('./img/', function (err, res) {
  if (err) {
    console.log('Error', err);
  } else {
    let pixelInfo;
    console.log(res)
    for(let i =0 ; i < res.length ; i++){
         directorySplit = res[i].split('/');
         console.log(directorySplit)
         traitName = directorySplit[3];
         traitType = directorySplit[2]; 
         if(directorySplit.length==4){
            let pixelInfo = getPixelInformation(res[i],traitName,traitType);
            pixels.push(pixelInfo);

         }
    }


  }
});



function getPixelInformation(fileName,traitName,traitType) {
    const trait = {};
    Jimp.read(fileName, function (err, image) {
        if(!image) return;
        const w = image.bitmap.width; //  width of the image
        const h = image.bitmap.height;
        const name = image.na
        let compactFormat ='';
        let trait = {};
        let pixelCount = 0;
        for(let i=0; i<w; i++) {
            for(let y=0; y<h; y++){
                const color = decimalToHexString(image.getPixelColor(i, y));
                
                //conversion of X,Y to letters for compact format
                const letterI = String.fromCharCode(i + 'A'.charCodeAt(0));
                const letterY = String.fromCharCode(y + 'A'.charCodeAt(0));
                //we ignore blank pixels
                if(color != "0"){
                    if(colors.indexOf(color) == -1) {
                      colors.push(color)
                      console.log('.c'+colors.indexOf(color)+ '{fill: #'+ color + ' }')
                    };
                      const position = colors.indexOf(color);
                      pixelCount ++;
                      compactFormat = compactFormat + (letterI+ letterY) + (position.toString().length ==1 ? "0" +position.toString(): position.toString()) ;
            
                }
            
               
            }
        }
        trait = {traitName:removeExtension(traitName),traitType:traitType,pixelCount:pixelCount,pixels:compactFormat}
        console.log(trait)
    });
}




function decimalToHexString(number)
{
  if (number < 0)
  {
    number = 0xFFFFFFFF + number + 1;
  }

  return number.toString(16).toUpperCase();
}


function removeExtension(filename) {
    return filename.substring(0, filename.lastIndexOf('.')) || filename;
  }