import { LightningElement, wire } from 'lwc';

import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import USER_ROLE_NAME_FIELD from '@salesforce/schema/User.UserRole.Name';
import USER_PROFILE_NAME from '@salesforce/schema/User.Profile.Name';

import initData from '@salesforce/apex/NetSuiteItemsListController.initData';
import getFilteredNetSuiteItems from '@salesforce/apex/NetSuiteItemsListController.getFilteredNetSuiteItems';


export default class NetSuiteItemsList extends LightningElement {
    
    get columns() {
        return [
            {        
                label: 'Item Number',
                fieldName: 'Id',
                type: 'url',
                typeAttributes: {
                    label: { fieldName: 'Name' },
                    target: '_self'
                }
            },
            { label: 'Display Name', fieldName: 'breadwinner_ns__DisplayName__c', type:'text'},
            { label: 'Attached image', fieldName: 'imageURL', type:'imageURL',
                typeAttributes: {
                    showImage: { fieldName: 'shouldShowImage' }
                },
                cellAttributes: { alignment: 'center' }
            },
            { label: 'Center Stone Weight', fieldName: 'ncf_item_stoneweight1__c', type:'text'},
            { label: 'Total Carat Weight', fieldName: 'ncf_item_stdweight__c', type:'text'},
            { label: 'Selected Location', fieldName: 'Location', type:'text'},
            { label: 'Location Qty Avail', fieldName: 'LocationQtyAvail', type:'text'},
            { label: 'Location On Hand', fieldName: 'LocationOnHand', type:'text', sortable: true},
            { label: 'Location Qty In Transit', fieldName: 'LocationQtyInTransit', type:'text'},
            { label: 'Location Stock', fieldName: 'Location_Stock__c', type:'text'},
            { label: 'Price', fieldName: 'Base_Price__c', type:'text'},

            ...(this.showCostMarginFields ? [
                { label: 'Cost', fieldName: 'breadwinner_ns__Cost__c', type: 'text', sortable: true },
                { label: 'Margin %', fieldName: 'Margin_Percent__c', type: 'text' },
                { label: 'Replacement Cost', fieldName: 'ncf_item_replacementcost__c', type: 'text' },
            ] : []),

            { label: 'Total Weight', fieldName: 'Total_Weight_Displayed_in_Table__c', type:'text'},
            { label: 'Owner Type', fieldName: 'ncf_item_ownertype__c', type:'text'},
            { label: 'Preferred Vendor', fieldName: 'ncf_item9__c', type:'text'},
            { label: 'Division', fieldName: 'breadwinner_ns__ClassName__c', type:'text'},
            { label: 'Merchandise Dept', fieldName: 'ncf_item_psgss_merc_dept__c', type:'text'},
            { label: 'Group Code', fieldName: 'ncf_item_groupcode__c', type:'text'},
            { label: 'Promo Code', fieldName: 'ncf_item_groupcode__c', type:'text'},
            { label: 'Is Serial', fieldName: 'ncf_item_serialized_item_type__c', type:'text'},
            { label: 'Watch Serial #', fieldName: 'ncf_item_watchserial__c', type:'text'},
            { label: 'Date First Receipt', fieldName: 'ncf_item_datefirstreceipt__c', type:'text'},
            { label: 'Date Last Receipt', fieldName: 'ncf_item_datelastreceipt__c', type:'text'},
            // { label: 'On Website', fieldName: 'Is_On_Website__c', type:'text'}
        ];
    }

    data = [];
    filter = {};
    subtotals;
    pageNumber = 1
    showSpinner = false;
    hasTotalsClass = '';
    showCostMarginFields = false;

    preferredVendorOptions = [];
    promoCodeOptions = [];
    groupCodeOptions = [];
    divisionNameOptions = [];
    merchandiseDeptOptions = [];
    ownerTypeOptions = [];
    centerStoneShapeOptions = [];
    metalTypeOptions = [];

    centerStoneClarityOptions = [];
    preferredLocationOptions = [];

    @wire(getRecord, { recordId: USER_ID, fields: [USER_ROLE_NAME_FIELD, USER_PROFILE_NAME]}) 
    userDetails({error, data}) {
        if (data) {
            const userRole = data.fields.UserRole?.value?.fields?.Name?.value;
            const profileName = data.fields.Profile?.value?.fields?.Name?.value;

            this.showCostMarginFields = 
                userRole === 'Executive' || 
                userRole === 'Manager' || 
                profileName === 'System Administrator';
        }

        if (error) {
            console.error('Error loading user details:', error);
        }
    }

    connectedCallback() {
        this.showSpinner = true;
        initData()
            .then(initialData => {
                console.log(initialData.pageResult);
                this.showNetSuiteItems(initialData.pageResult);

                this.preferredVendorOptions = initialData.preferredVendorOptions;
                this.promoCodeOptions = initialData.promoCodeOptions;
                this.groupCodeOptions = initialData.groupCodeOptions;
                this.divisionNameOptions = initialData.divisionNameOptions;
                this.merchandiseDeptOptions = initialData.merchandiseDeptOptions;
                this.ownerTypeOptions = initialData.ownerTypeOptions;
                this.centerStoneShapeOptions = initialData.centerStoneShapeOptions;
                this.metalTypeOptions = initialData.metalTypeOptions;
                this.centerStoneClarityOptions = initialData.centerStoneClarityOptions;
                this.preferredLocationOptions = initialData.preferredLocationOptions;
            })
    }

    sortBy;
    sortDirection;

    handleSort(event) {
        // const { fieldName: newSortedBy } = event.detail; // Отримуємо нове поле
        
        // let sortDirection;
        
        // if (this.sortBy === newSortedBy) {
        //     sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
        // } else {
        //     sortDirection = 'asc';
        // }

        // this.sortBy = newSortedBy;
        // this.sortDirection = sortDirection;

        // this.sortData(newSortedBy, sortDirection);

        const { fieldName: newSortedBy } = event.detail;
    
        if (this.sortBy === newSortedBy) {
            this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
        } else {
            this.sortDirection = 'asc';
        }
        this.sortBy = newSortedBy;
        this.filterData();
    }

    sortData(fieldname, direction) {
        if (!fieldname && !direction) return;

        let parseData = [...this.data];
        let keyValue = (a) => {
             return typeof a[fieldname] === 'string' ? a[fieldname].toLowerCase() : a[fieldname];
        };
        let isReverse = direction === 'asc' ? 1 : -1;

        parseData.sort((x, y) => {
            x = keyValue(x) || ''; 
            y = keyValue(y) || '';
            
            return isReverse * ((x > y) - (y > x));
        });

        this.data = parseData;
    }


    handleNameSeachChange(event) {
        this.filter.itemNumber = event.detail.value;
        console.log(JSON.stringify(this.filter));
        this.filterData();
    }

    handleMinPriceChange(event) {
        this.handleNumericFilterChange('minPrice', event);
    }

    handleMaxPriceChange(event) {
        this.handleNumericFilterChange('maxPrice', event);
    }

    handleCaratWeightMinChange(event) {
        this.handleNumericFilterChange('caratWeightMin', event);
    }

    handleCaratWeightMaxChange(event) {
        this.handleNumericFilterChange('caratWeightMax', event);
    }

    handlePreferredLocationChange(event) {
        this.filter.preferredLocation = event.detail.value;
        console.log(JSON.stringify(this.filter));
        this.filterData();
    }

    handleDisplayNameChange(event) {
        this.filter.displayName = event.detail.value;
        console.log(JSON.stringify(this.filter));
        this.filterData();
    }

    handlePreferredVendorChange(event) {
        this.filter.preferredVendor = event.detail.value;
        console.log(JSON.stringify(this.filter));
        this.filterData();
    }

    handlePromoCodeChange(event) {
        this.filter.promoCode = event.detail.value;
        console.log(JSON.stringify(this.filter));
        this.filterData();
    }

    handleIsSerializedChange(event) {
        this.filter.isSerialized = event.target.checked;
        console.log(JSON.stringify(this.filter));
        this.filterData();
    }

    handleGroupCodeChange(event) {
        this.filter.groupCode = event.detail.value;
        console.log(JSON.stringify(this.filter));
        this.filterData();
    }

    handleDivisionNameChange(event) {
        this.filter.divisionName = event.detail.value;
        console.log(JSON.stringify(this.filter));
        this.filterData();
    }

    handleMerchandiseDeptChange(event) {
        this.filter.merchandiseDept = event.detail.value;
        console.log(JSON.stringify(this.filter));
        this.filterData();
    }

    handleOwnerTypeChange(event) {
        this.filter.ownerType = event.detail.value;
        console.log(JSON.stringify(this.filter));
        this.filterData();
    }

    handleOnWebsiteChange(event) {
        this.filter.onWebsite = event.target.checked;
        console.log(JSON.stringify(this.filter));
        this.filterData();
    }

    handleOnHandQty(event) {
        this.filter.onHandQty = event.target.checked;
        console.log(JSON.stringify(this.filter));
        this.filterData();
    }

    handleCenterStoneShapeChange(event) {
        this.filter.centerStoneShape = event.detail.value;
        console.log(JSON.stringify(this.filter));
        this.filterData();
    }

    handleCenterStoneLengthMinChange(event) {
        this.handleNumericFilterChange('centerStoneLengthMin', event);
    }

    handleCenterStoneLengthMaxChange(event) {
        this.handleNumericFilterChange('centerStoneLengthMax', event);
    }

    handleMetalTypeChange(event) {
        this.filter.metalType = event.detail.value;
        console.log(JSON.stringify(this.filter));
        this.filterData();
    }

    handleCenterStoneWeightMinChange(event) {
        this.handleNumericFilterChange('centerStoneWeightMin', event);
    }

    handleCenterStoneWeightMaxChange(event) {
        this.handleNumericFilterChange('centerStoneWeightMax', event);
    }

    handleCenterStoneClarityChange(event) {
        this.filter.centerStoneClarity = event.detail.value;
        console.log(JSON.stringify(this.filter));
        this.filterData();
    }

    handleRollUpSubitemsChange(event) {
        this.filter.rollUpSubitemsChange = event.target.checked;
        console.log(JSON.stringify(this.filter));
        this.filterData();
    }

    filterData() {
        this.pageNumber = 1;
        clearTimeout(this.timeoutId);

        this.timeoutId = setTimeout(() => {
            this.showSpinner = true;
            getFilteredNetSuiteItems({
                    filterJSON: JSON.stringify(this.filter),
                    sortField: this.sortBy || null,
                    sortDirection: this.sortDirection || null,
                    pageNumber: this.pageNumber
                })
                .then(pageResult => {
                    this.showNetSuiteItems(pageResult); 
                })
                .catch(error => {
                    this.showSpinner = false;
                    console.error('Error:', JSON.stringify(error));
                    console.error('Body:', error?.body);
                    console.error('Message:', error?.body?.message || error?.message || error);

                    // console.error('Error filtering NetSuite items:', JSON.stringify(error));
                    // console.error('Apex error:', error.body.message);
                    // console.error('Apex error:', error.body);
                });
        }, 500);
    }

    showNetSuiteItems(pageResult, isLoadedMore) {
        if (this.pageNumber == 1) {
            this.subtotals = pageResult.subtotals;
        }

        this.showSpinner = false;
        if (pageResult.netSuiteItems.length === 0 && !isLoadedMore) {
            this.data = [];
            return;
        }

        let dataItems = [];

        pageResult.netSuiteItems.forEach(item => {
            let dataItem = { ...item };

            dataItem.Base_Price__c = this.formatCurrency(dataItem.Base_Price__c);
            dataItem.breadwinner_ns__Cost__c = this.formatCurrency(dataItem.breadwinner_ns__Cost__c);
            dataItem.ncf_item_replacementcost__c = this.formatCurrency(dataItem.ncf_item_replacementcost__c);
            
            if (this.filter.rollUpSubitemsChange && pageResult.rollUpQty) {
                dataItem.Location = this.filter.preferredLocation || 'All Locations';
                const qty = pageResult.rollUpQty[dataItem.Id];
                dataItem.LocationQtyAvail = qty ? qty.LocationQtyAvail : 0;
                dataItem.LocationOnHand = qty ? qty.LocationOnHand : 0;
                dataItem.LocationQtyInTransit = qty ? qty.LocationQtyInTransit : 0;
            } else if (this.filter.preferredLocation) {
                dataItem.Location = this.filter.preferredLocation;

                const inv = dataItem.breadwinner_ns__BWInventoryLocations__r?.find(
                    loc => loc.breadwinner_ns__Location__r.Name === this.filter.preferredLocation
                );

                if (inv) {
                    dataItem.LocationQtyAvail = parseInt(inv.breadwinner_ns__QuantityAvailable__c) || 0;
                    dataItem.LocationOnHand = parseInt(inv.breadwinner_ns__QuantityOnHand__c) || 0;
                    dataItem.LocationQtyInTransit = parseInt(inv.breadwinner_ns__QuantityBackOrdered__c) || 0;
                } else {
                    dataItem.LocationQtyAvail = dataItem.Total_Qty_Avail__c || 0;
                    dataItem.LocationOnHand = dataItem.Total_Qty_On_Hand__c || 0;
                    dataItem.LocationQtyInTransit = dataItem.Total_Qty_In_Transit__c || 0;
                }
            } else {
                dataItem.Location = 'All Locations';
                dataItem.LocationQtyAvail = dataItem.Total_Qty_Avail__c || 0;
                dataItem.LocationOnHand = dataItem.Total_Qty_On_Hand__c || 0;
                dataItem.LocationQtyInTransit = dataItem.Total_Qty_In_Transit__c || 0;
            }

            dataItem.imageURL = dataItem.imageId__c 
                ? '/sfc/servlet.shepherd/document/download/' + dataItem.imageId__c
                : null;
            dataItem.shouldShowImage = true;
            dataItem.Id = '/' + dataItem.Id;
            dataItems.push(dataItem);
        })

        if (pageResult.showSubtotals) {
            this.data.shift();
        }
        
        if (isLoadedMore) {
            this.data = [...this.data, ...dataItems];
        } else {
            this.data = dataItems;
        }

        if (pageResult.showSubtotals) {
            this.hasTotalsClass = 'has-totals';

            let totalItem = {
                "breadwinner_ns__DisplayName__c" : "Total",
                "shouldShowImage" : false,
                "LocationQtyAvail" : this.subtotals.totalLocationQtyAvail,
                "LocationOnHand" : this.subtotals.totalLocationOnHand,
                "LocationQtyInTransit" : this.subtotals.totalLocationQtyInTransit,
                "Base_Price__c" : this.formatCurrency(this.subtotals.totalPrice),
                "breadwinner_ns__Cost__c" : this.formatCurrency(this.subtotals.totalCost),
                "Margin_Percent__c" : this.subtotals.totalMargin,
                "ncf_item_replacementcost__c" : this.formatCurrency(this.subtotals.totalReplacementCost),
                "Total_Weight_Displayed_in_Table__c" : this.subtotals.totalWeight,
            };
            
            this.data = [totalItem, ...this.data];
        } else {
            this.hasTotalsClass = '';
        }

    }

    formatCurrency(value) {
        if (value == null) 
            return '$0.00';
        return '$' + Number(value).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    }

    handleLoadMore() {
        this.pageNumber ++;
        this.showSpinner = true;
        getFilteredNetSuiteItems({
                filterJSON: JSON.stringify(this.filter),
                sortField: this.sortBy || null,
                sortDirection: this.sortDirection || null,
                pageNumber: this.pageNumber
            })
            .then(pageResult => {
                this.showNetSuiteItems(pageResult, true);
            })
            .catch(error => {
                this.showSpinner = false;
                console.error('Error:', JSON.stringify(error));
                console.error('Body:', error?.body);
                console.error('Message:', error?.body?.message || error?.message || error);
            });
    }

    handleNumberKeydown(event) {
        const value = event.target.value;
        
        if (event.key === ',') {
            event.preventDefault();
        }

        if (value.includes('.')) {
            const dotIndex = value.indexOf('.');
            const cursorPos = event.target.selectionStart;
            const decimals = value.substring(dotIndex + 1);

            if (cursorPos > dotIndex && decimals.length >= 2 && /^[0-9]$/.test(event.key)) {
                event.preventDefault();
            }
        }
    }

    handleNumericFilterChange(fieldName, event) {
        let value = event.detail.value;

        if (value && value.endsWith('.')) {
            value = value.slice(0, -1);
        }

        this.filter[fieldName] = value ? value : null;

        console.log(JSON.stringify(this.filter));
        this.filterData();
    }

}