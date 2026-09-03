import { LightningElement, api } from 'lwc';
import getRelatedFiles from '@salesforce/apex/FileListerController.getRelatedFiles';
import getRecordStatus from '@salesforce/apex/FileListerController.getRecordStatus';
// import getRecordData from '@salesforce/apex/FileListerController.getRecordData';
import handleChangeNameDescriptionPicklist from '@salesforce/apex/FileListerController.changeNameDescriptionPicklist';
import getPicklistValues from '@salesforce/apex/FileListerController.getPicklistValues';
import deleteRecord from '@salesforce/apex/FileListerController.deleteRecord';
import {
    registerRefreshContainer,
    unregisterRefreshContainer,
    registerRefreshHandler,
    unregisterRefreshHandler ,
    REFRESH_ERROR,
    REFRESH_COMPLETE,
    REFRESH_COMPLETE_WITH_ERRORS,
} from "lightning/refresh";
import {NavigationMixin} from 'lightning/navigation'
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { RefreshEvent } from "lightning/refresh";


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
    { label: 'Attachment Name', fieldName: 'attachmentName', type: 'string', sortable: true },
    {
        label: 'Description',
        fieldName: 'description',
        sortable: true

    },

    // { label: 'File Type', fieldName: 'FileType', sortable: true },
    { label: 'Type', fieldName: 'attachmentType', type: 'string', sortable: true },
    { label: 'Uploaded On', fieldName: 'CreatedDate', type: 'date', typeAttributes: {
        day:'numeric',
        month:'short',
        year:'numeric',
        hour:'2-digit',
        minute:'2-digit',
        second:'2-digit',
        hour12:true}
        , sortable: true },
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
    isModalOpen;
    isSecondModalOpen = false;
    tmpRow;
    oldType;
    // hasEdit = false;
    formData = {
        name: '',
        description: '',
        type: []
    };
    FilterFields= {
        OCE__Status__c: null
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

    connectedCallback() {
        this.getRecordStatus();

        //this.refreshContainerID = registerRefreshContainer(this, this.handleRefresh.bind(this));
        this.refreshHandlerID = registerRefreshHandler(this.template.host, this.handleRefresh.bind(this));
        getPicklistValues({recordId: this.recordId ,type: 'Pre_Approval_Types__c' }).then(result => {
            const preItems = result.map(item => ({
                label: item.label,
                value: item.value,
                type: 'Pre-Approval'
            }));

            this.formData.type = [...preItems];
            this.formData.name = 'Pre-Approval';

            return getPicklistValues({recordId: this.recordId, type: 'Post_Approval_Types__c' });
        })
        .then(postResult => {

            const postItems = postResult.map(item => ({
                label: item.label,
                value: item.value,
                type: 'Post-Approval'
            }));

            this.formData.type = [...this.formData.type, ...postItems];


            console.log(this.formData);

        })
        .catch(error => {
            console.error(error);
            this.error = error;
        });


    }
    renderedCallback(){}
    disconnectedCallback() {
        unregisterRefreshHandler(this.refreshHandlerID);
    }

    get typeOptions() {
        return ['Pre-Approval', 'Post-Approval'].map(type => ({
            label: type,
            value: type
        }));
    }

    get categoryOptions() {

        const activeParentType = this.formData?.newParentType || this.formData?.currentParentType;

        if (!activeParentType || !Array.isArray(this.formData?.type)) {
            return [];
        }

        return this.formData.type
            .filter(item => item.type === activeParentType)
            .map(item => ({
                label: item.label,
                value: item.value
            }));
        }


    getRowActions(row, doneCallback) {
        if (this.FilterFields.OCE__Status__c !== 'Draft') {
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


/*
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
*/

// 1. Your handler should NOT take arguments usually
handleRefresh() {

    return new Promise((resolve) => {
        // this.isLoading = true;
        this.getRelatedFiles()
            .then(() => {
                resolve(true);
            })
            .catch((error) => {
                console.error('Refresh failed', error);
                resolve(false); // Signal failure
            });
    });
}

    getRecordStatus(){
        getRecordStatus({ recordId: this.recordId })
        .then(result => {

            this.FilterFields = {
                ...this.FilterFields,
                OCE__Status__c: result.OCE__Status__c
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
            console.log(result);
            // this.isLoading = false;
            this.files = result.map(item => {
                return {
                    ...item.file,
                    attachmentType: item.attachmentType,
                    attachmentName: item.attachmentName,
                    fileLink: `/sfc/servlet.shepherd/version/download/${item.file.Id}`,
                    Id : item.file.ContentDocumentId,
                    description: item.file.Description ? item.file.Description : '',
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
        this.formData = {
            ...this.formData,
            name: row.Title,
            description: row.description,
            // oldType : row.attachmentType,
            ContentDocumentId: row.Id
        }



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
                this.tmpRow = row;
                // this.oldType = row.attachmentType;

                const rawParsed = JSON.parse(JSON.stringify(this.tmpRow));
                const currentRow = Array.isArray(rawParsed) ? rawParsed[0] : rawParsed;

                this.formData.currentType = currentRow?.attachmentName;
                this.formData.currentParentType = currentRow?.attachmentType;
                console.log('Updated formData:', JSON.parse(JSON.stringify(this.formData)));
                this.isSecondModalOpen = true;

                /*
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: row.Id,
                        actionName: 'edit',
                    },
                })
                // this.hasEdit = true;
                */
                break;

            case 'delete_record':
                this.tmpRow = row;
                this.isModalOpen = true;
                break;
            default:
                break;
        }
    }


    closeModal(){
        this.tmpRow = null;
        this.isModalOpen = false;
        this.isSecondModalOpen = false;
        this.formData = {
            ...this.formData,
            newType: ''
        }
    }

    handleDeleteConfirmed(){

        deleteRecord({recordId: this.tmpRow.Id }).then(result => {
                    if(result == 'success'){
                        const evt = new ShowToastEvent({
                            title: 'Success',
                            message: 'File deleted successfully',
                            variant: 'success',
                            mode: 'dismissable'
                        });
                        this.dispatchEvent(evt);
                    }
                    else{
                        const evt = new ShowToastEvent({
                            title: 'File is not deleted',
                            message: 'Error occured',
                            variant: 'error',
                            mode: 'dismissable'
                        });
                        this.dispatchEvent(evt);
                    }
                }).then(() => {
                    this.dispatchEvent(new RefreshEvent());
                })
                .catch(error => {
                    console.log(error);
                    const evt = new ShowToastEvent({
                            title: 'File is not deleted',
                            message: 'Server Error occured',
                            variant: 'error',
                            mode: 'dismissable'
                        });
                        this.dispatchEvent(evt);
                });
                this.tmpRow = null;
                this.isModalOpen = false;
    }

    handleInputChange(event){
        const field = event.target.dataset.id;
        const value = event.target.value;
        this.formData = {
            ...this.formData,
            [field]: value

        };
    }
    handleSave(event){

        const FIELD_API_MAP = {
            'Pre-Approval': 'Pre_Approval_Types__c',
            'Post-Approval': 'Post_Approval_Types__c'
        };

        if (this.formData?.newType && !this.formData?.newParentType) {
            this.formData = {
                ...this.formData,
                newParentType: this.formData.currentParentType
            };
        }
        this.formData = {
            ...this.formData,
            currentParentType: FIELD_API_MAP[this.formData.currentParentType] || this.formData.currentParentType,
            newParentType: FIELD_API_MAP[this.formData.newParentType] || this.formData.newParentType
        };
        this.isLoading = true;
        console.log('PASSED VALUES ', this.formData)


        handleChangeNameDescriptionPicklist({
            recordId: this.tmpRow.Id,
            name: this.formData.name,
            description: this.formData.description,
            sourceType: this.formData.currentType ,
            targetType: this.formData.newType,
            sourceCategoryFieldName:this.formData.currentParentType,
            targetCategoryFieldName:this.formData.newParentType,
            meetingId: this.recordId }).then(result => {
            if(result == 'success'){
                this.isLoading = false;
                const evt = new ShowToastEvent({
                    title: 'Success',
                    message: 'File updated successfully',
                    variant: 'success',
                    mode: 'dismissable'
                });
                this.dispatchEvent(evt);
            }
            else{
                const evt = new ShowToastEvent({
                    title: 'File is not updated',
                    message: 'Error occured',
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(evt);
            }
        }).then(() => {
            this.isSecondModalOpen = false;
            this.dispatchEvent(new RefreshEvent());
        })
    }
}
