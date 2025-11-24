import { LightningElement, api } from 'lwc';
import getRelatedFiles from '@salesforce/apex/FileListerController.getRelatedFiles';
import getRecordStatus from '@salesforce/apex/FileListerController.getRecordStatus';
import {
    registerRefreshContainer,
    unregisterRefreshContainer,
    REFRESH_ERROR,
    REFRESH_COMPLETE,
    REFRESH_COMPLETE_WITH_ERRORS,
} from "lightning/refresh";
import {NavigationMixin} from 'lightning/navigation'


const ACTIONS = [
    { label: 'View', name: 'view_record' },
    { label: 'Edit', name: 'edit_record' },
    { label: 'Delete', name: 'delete_record' } 
];

const BASE_COLUMNS = [
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
    { label: 'Uploaded On', fieldName: 'CreatedDate', type: 'date', sortable: true },
    {
        type: 'action',
        typeAttributes: { rowActions: '' } 
    }
];

export default class RelatedFilesDatatable extends NavigationMixin(LightningElement) {
    @api recordId;
    columns = [];
    files;
    error;
    isLoading = false;
    sortBy;
    sortDirection;
    FilterFields= {
        Status__c: null
    }

    
    constructor() {
        super();
        this.columns = BASE_COLUMNS.map(col => {
            if (col.type === 'action') {
                return { ...col, typeAttributes: { rowActions: this.getRowActions.bind(this) } };
            }
            return col;
        });
    }

    
    getRowActions(row, doneCallback) {
        if (this.FilterFields.Status__c === 'Draft') {
            const approvedActions = ACTIONS.filter(action => action.name !== 'delete_record');
            doneCallback(approvedActions);
        } else {
            doneCallback(ACTIONS);
        }
    }




    handleSort(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }

    
    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.files));
        let keyValue = (a) => {
            if (fieldname === 'fileLink') return a.Title;
            return a[fieldname];
        };
        let isReverse = direction === 'asc' ? 1: -1;
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : '';
            y = keyValue(y) ? keyValue(y) : '';
            return isReverse * ((String(x).toLowerCase() > String(y).toLowerCase()) - (String(y).toLowerCase() > String(x).toLowerCase()));
        });
        this.files = parseData;
    }
    
    refreshContainerID;

    connectedCallback() { 
        this.getRecordStatus();
        this.refreshContainerID = registerRefreshContainer(this, this.handleRefresh.bind(this)); 
    }
    disconnectedCallback() { 
        unregisterRefreshContainer(this.refreshContainerID); 
    }
    

    handleRefresh(refreshPromise) {
    return refreshPromise.then( (status) => {
        if (status === REFRESH_COMPLETE) {
            this.isLoading = true;
            setTimeout(() => {
                this.getRelatedFiles();
            }, 2000);
        } else if (status === REFRESH_COMPLETE_WITH_ERRORS) {
            console.warn("Done, with issues refreshing some components");
        } else if (status === REFRESH_ERROR) {
            console.error("Major error with refresh.");
        }
    });
    }

    getRecordStatus(){
        getRecordStatus({ recordId: this.recordId })
        .then(result => {
            this.FilterFields = {
                ...this.FilterFields,
                Status__c: result.OCE__Status__c
            }
        }).then(() => {
            this.getRelatedFiles();
        })
        .catch(error => {
            this.error = error;
        });
    }

    getRelatedFiles(){
        getRelatedFiles({ recordId: this.recordId })
        .then(result => {
            this.isLoading = false;
            this.files = result.map(file => {
                return {
                    ...file,
                    fileLink: `/sfc/servlet.shepherd/version/download/${file.Id}`,
                    Id : file.ContentDocumentId
                };
            });
            this.error = undefined;
            if(this.sortBy) {
                this.sortData(this.sortBy, this.sortDirection);
            }
        })
        .catch(error => {
            this.error = error;
            this.files = undefined;
        });
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        switch (actionName) {
            case 'view_record':
                this[NavigationMixin.Navigate]({
                    type: 'standard__namedPage',
                    attributes: {
                        pageName:'filePreview'
                    },
                    state:{ 
                        selectedRecordId: row.Id,
                    }
                });
                break;
            case 'edit_record':
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: row.Id,
                        actionName: 'edit',
                    },
                });
                break;
            case 'delete_record':
                // Implement your delete logic here (e.g., call Apex delete method)
                console.log(`Deleting file with ContentDocumentId: ${row.Id}`);
                // After successful delete, you should call this.getRelatedFiles() to refresh the list.
                break;
            default:
                break;
        }
    }
}