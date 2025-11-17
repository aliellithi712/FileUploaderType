import { LightningElement, track, wire } from 'lwc';
//import class called TestClass
import getMessage from '@salesforce/apex/StringReturner.getMessage';


export default class MyFirstWebComponent extends LightningElement {
    @wire(getMessage)
    message;

    get messageText() {
        return this.message.data;
    }

    @track
    contacts = [
        {
            Id: 1,
            Name: 'Amy Taylor',
            Title: 'VP of Engineering',
        },
        {
            Id: 2,
            Name: 'Michael Jones',
            Title: 'VP of Sales',
        },
        {
            Id: 3,
            Name: 'Jennifer Wu',
            Title: 'CEO',
        },
    ];
}