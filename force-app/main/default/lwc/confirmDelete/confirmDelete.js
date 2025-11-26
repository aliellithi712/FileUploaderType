import { LightningElement } from 'lwc';

export default class DeleteConfirmationModal extends LightningElement {

    // Handles the 'Cancel' button click and the close icon click.
    handleCancel() {
        this.dispatchEvent(new CustomEvent('closedeletemodal'));
    }

    // Handles the 'Delete' button click.
    handleConfirm() {
        this.dispatchEvent(new CustomEvent('confirmdeletemodal'));
    }
}