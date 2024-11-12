function getFirestore(){
  var email = "firebase-writer@feedforge-3fb4c.iam.gserviceaccount.com";
  var key = "";
  var projectId = "feedforge-3fb4c";
  return FirestoreApp.getFirestore(email,key,projectId);
}


function myFunction() {
  const firestore = getFirestore();
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheetname = "Bot";
  const sheet = ss.getSheetByName(sheetname);
  const lastRow = sheet.getLastRow();
  const lastCol = sheet.getLastColumn();
  const dataSR = 2; // Starting row for data

  // Load last processed row from script properties
  const scriptProperties = PropertiesService.getScriptProperties();
  const lastProcessedRow = parseInt(scriptProperties.getProperty("lastProcessedRow") || dataSR, 10);

  // Only process new rows since the last processed row
  const sheetRange = sheet.getRange(lastProcessedRow + 1, 1, lastRow - lastProcessedRow, lastCol);
  const sheetData = sheetRange.getValues();

  for (var i = 0; i < sheetData.length; i++) {
    if (sheetData[i][1] !== '') {
      const data = {
        ID: sheetData[i][0].toString(),
        Numero: sheetData[i][1].toString(),
        Nombre: sheetData[i][2].toString(),
        Negocio: sheetData[i][3].toString(),
        Recomendacion: parseInt(sheetData[i][4], 10),
        Servicio: parseInt(sheetData[i][5], 10),
        Tiempo: parseInt(sheetData[i][6], 10),
        Calidad: parseInt(sheetData[i][7], 10),
        Ambiente: parseInt(sheetData[i][8], 10),
        Feedback: sheetData[i][9].toString(),
      };

      // Validate integer fields
      if (
        isNaN(data.Recomendacion) ||
        isNaN(data.Servicio) ||
        isNaN(data.Tiempo) ||
        isNaN(data.Calidad) ||
        isNaN(data.Ambiente)
      ) {
        Logger.log("Invalid data format in row " + (lastProcessedRow + 1 + i));
        continue; // Skip this row if validation fails
      }

      try {
        // Check if document with this ID exists
        const existingDoc = firestore.getDocument("Negocios/" + data.ID);
        firestore.updateDocument("Negocios/" + data.ID, data);
        Logger.log("Document updated with ID: " + data.ID);
      } catch (e) {
        // If not found, create a new document
        Logger.log("Document not found, creating new document with ID: " + data.ID);
        firestore.createDocument("Negocios/" + data.ID, data);
      }
    }
  }

  // Update the last processed row in script properties
  scriptProperties.setProperty("lastProcessedRow", lastRow);
}



