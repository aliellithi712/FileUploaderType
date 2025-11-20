import { LightningElement, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPicklistValues from '@salesforce/apex/PicklistHelper.getPicklistValues';
import assignType from '@salesforce/apex/ContentVersionHandler.assignType'
import { RefreshEvent } from "lightning/refresh";


export default class ProgressTabs extends LightningElement {
    @api recordId;
  currentStep = '1';
  currentPage = {
    first: true,
    second: false,
    third: false
  };
  uploadedFiles = [];
  options = [];
  value = '';


  @wire (getPicklistValues, { objectName: 'ContentVersion', fieldName: 'Type__c' })
    wiredPicklist({ error, data }) {
        if (data) {
            this.options = data.map(value => ({
                label: value,
                value: value
            }));
        } else if (error) {
            console.error('Error loading picklist values', error);
        }
    } 

  get isStepOne() {
    return this.currentStep === '1';
  }
  get isStepTwo() {
    return this.currentStep === '2';
  }
  

  get isFirstStep() {
    return this.currentStep === '1';
  }

  get isLastStep() {
    return this.currentStep === '2';
  }

  get acceptedFormats() {
        return ['.pdf', '.png'];
    }


  handleNext() {
    console.log("2 " , this.recordId)
    if (this.currentStep === '1') { 
        if(this.value == ''){
          const evt = new ShowToastEvent({
          title: 'Need to select a file type',
          message: 'Please select a file type',
          variant: 'error',
          mode: 'dismissable'
      });
        this.dispatchEvent(evt);
        }
        else{
            this.currentStep = '2';
            this.currentPage = { first: false, second: true, third: false }
        }

    } else if (this.currentStep === '2') {
        if(this.uploadedFiles.length == 0){
            const evt = new ShowToastEvent({
          title: 'Need to upload a file',
          message: 'Please upload a file',
          variant: 'error',
          mode: 'dismissable'
      });
        this.dispatchEvent(evt);
        }
        else{
      this.currentPage = { first: false, second: false, third: true }}
    }
  }

  handlePrevious() {
    
    if (this.currentStep === '2') {
      this.currentStep = '1';
      this.currentPage = { first: true, second: false, third: false }
    }
    
  }

  handleUploadFinished(event) {
    let fileId = '';
    const files = event.detail.files;
    files.forEach(ele => {
      fileId = ele.documentId;
    });

    const newFiles  = files.map( (file, i) => ({
        name: file.name,
        index: this.uploadedFiles.length + 1
        
    }))
    this.uploadedFiles = [...this.uploadedFiles, ...newFiles];

    assignType({flag: "upload",recordId: fileId, type: this.value}).then(result =>{
        if ( result == 'success' ){
        evt = new ShowToastEvent({
          title: 'Success',
          message: 'File uploaded successfully',
          variant: 'success',
          mode: 'dismissable'
      });
        this.dispatchEvent(evt);
        }
    })
    window.location.reload()
    // this.dispatchEvent(new RefreshEvent());

    }


    handleChange(event) {
        this.value = event.detail.value;
    }

}