import { LightningElement, api, wire } from 'lwc';
import getRelatedFiles from '@salesforce/apex/FileListerController.getRelatedFiles';
import {
  registerRefreshContainer,
  unregisterRefreshContainer,
  REFRESH_ERROR,
  REFRESH_COMPLETE,
  REFRESH_COMPLETE_WITH_ERRORS,
} from "lightning/refresh";
import { refreshApex } from '@salesforce/apex';



const COLUMNS = [
    { 
        label: 'File Name', 
        fieldName: 'fileLink', 
        type: 'url', 
        typeAttributes: { 
            label: { fieldName: 'Title' }, 
            target: '_blank' 
        },
        sortable: true 
    },
    { label: 'File Type', fieldName: 'FileType', sortable: true },
    { label: 'Type', fieldName: 'Type__c', type: 'string', sortable: true },
    { label: 'Uploaded On', fieldName: 'CreatedDate', type: 'date', sortable: true }
    
];

export default class RelatedFilesDatatable extends LightningElement {
    @api recordId; // Receives the current record ID from the Lightning Record Page
    columns = COLUMNS;
    files;
    error;
    isLoading = false;
    
    refreshContainerID;

    connectedCallback() { 
        this.getRelatedFiles();
        this.refreshContainerID = registerRefreshContainer(this, this.handleRefresh.bind(this)); }
    disconnectedCallback() { unregisterRefreshContainer(this.refreshContainerID); }
    


    handleRefresh(refreshPromise) {
    return refreshPromise.then( (status) => {
      if (status === REFRESH_COMPLETE) {
        this.isLoading = true;
        setTimeout(() => {
          this.getRelatedFiles();
        }, 2000);
        console.log("Done refreshing all components");
      } else if (status === REFRESH_COMPLETE_WITH_ERRORS) {
        console.warn("Done, with issues refreshing some components");
      } else if (status === REFRESH_ERROR) {
        console.error("Major error with refresh.");
      }
    });
  }


    getRelatedFiles(){
        getRelatedFiles({ recordId: this.recordId })
        .then(result => {
            this.isLoading = false;
            this.files = result.map(file => {
                return {
                    ...file,
                    fileLink: `/sfc/servlet.shepherd/version/download/${file.Id}`
                };
            });
            this.error = undefined;
        })
        .catch(error => {
            this.error = error;
            this.files = undefined;
        });
    }


    /*
    @wire(getRelatedFiles, { recordId: '$recordId' })
    wiredFiles({ error, data }) {
        this._wiredResult = data;
        if (data) {
            this.files = data.map(file => {
                return {
                    ...file,
                    fileLink: `/sfc/servlet.shepherd/version/download/${file.Id}`
                };
            });
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.files = undefined;
        }
    }
        */
}