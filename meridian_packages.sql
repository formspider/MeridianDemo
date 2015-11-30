--------------------------------------------------------
--  File created - Wednesday-November-25-2015   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for View MD_CUSTOMER_ORDERS
--------------------------------------------------------

  CREATE OR REPLACE FORCE VIEW "MD_CUSTOMER_ORDERS" ("ID", "CUSTOMER_ID", "DATE_ORDERED", "DATE_SHIPPED", "SALES_REP_ID", "LAST_NAME", "TOTAL", "PAYMENT_TYPE_ID", "PAYMENT_TYPE", "ORDER_FILLED", "SLICED") AS 
  select   o.ID,
         o.CUSTOMER_ID,
         o.DATE_ORDERED,
         o.DATE_SHIPPED,  
         o.SALES_REP_ID,
         e.LAST_NAME,
         o.TOTAL,
         o.PAYMENT_TYPE_ID,
         p.PAYMENT_TYPE,
         o.ORDER_FILLED,
        'N' as SLICED
from  S_ORD o LEFT OUTER JOIN S_PAYMENT_TYPE p on o.payment_type_id=p.id
join S_EMP e on o.sales_rep_id=e.id
order by o.id desc;
--------------------------------------------------------
--  DDL for View MD_ORDER_ITEMS
--------------------------------------------------------

  CREATE OR REPLACE FORCE VIEW "MD_ORDER_ITEMS" ("ORD_ID", "ITEM_ID", "PRODUCT_ID", "NAME", "SHORT_DESC", "IMAGE", "PRICE", "QUANTITY", "QUANTITY_SHIPPED", "TOTAL") AS 
  select i.ORD_ID,
       i.ITEM_ID,
       i.PRODUCT_ID,
       p.NAME,
       p.SHORT_DESC,
       g.IMAGE,
       i.PRICE,
       i.QUANTITY,
       i.QUANTITY_SHIPPED,
       i.PRICE*i.QUANTITY_SHIPPED as total
from S_ORD o left outer join  S_ITEM i on o.ID=i.ORD_ID
 join S_PRODUCT p on i.PRODUCT_ID=p.ID
 join S_IMAGE g on p.image_id=g.id
 order by i.ORD_ID;
--------------------------------------------------------
--  DDL for Trigger MD_CUSTOMER_ORDERS_TRIGGER
--------------------------------------------------------

  CREATE OR REPLACE TRIGGER "MD_CUSTOMER_ORDERS_TRIGGER" 
INSTEAD OF DELETE OR INSERT OR UPDATE ON MD_CUSTOMER_ORDERS
--FOR EACH ROW
BEGIN
     
   IF inserting THEN
        
         INSERT INTO s_ord
          (ID,CUSTOMER_ID,DATE_ORDERED,DATE_SHIPPED, SALES_REP_ID,
           TOTAL, PAYMENT_TYPE_ID,ORDER_FILLED)
         VALUES 
           (:new.ID,:new.CUSTOMER_ID,:new.DATE_ORDERED,:new.DATE_SHIPPED, :new.SALES_REP_ID,
            :new.TOTAL,:new.PAYMENT_TYPE_ID,:new.ORDER_FILLED);
         sb.print('INSERTED ORDER');
     END IF; 
     
      IF updating ('TOTAL') THEN 
        update s_ord set total = :new.TOTAL
          where ID=:new.ID and CUSTOMER_ID=:new.CUSTOMER_ID;
      --sb.print('UPDATED ORDER TOTAL');
      END IF;
      
       IF updating ('PAYMENT_TYPE') THEN 
          update s_ord set payment_type_id = :new.payment_type_id
          where ID=:new.ID and CUSTOMER_ID=:new.CUSTOMER_ID;
      
       END IF;
       
       IF deleting THEN 
          DELETE FROM s_ord
          WHERE ID=:old.ID
            AND CUSTOMER_ID=:old.CUSTOMER_ID
             AND DATE_ORDERED=:old.DATE_ORDERED 
             AND SALES_REP_ID=:old.SALES_REP_ID;
          sb.print('DELETED');   
      END IF; 
END;
/
ALTER TRIGGER "MD_CUSTOMER_ORDERS_TRIGGER" ENABLE;
--------------------------------------------------------
--  DDL for Trigger MD_ORDER_ITEMS_TRIGGER
--------------------------------------------------------

  CREATE OR REPLACE TRIGGER "MD_ORDER_ITEMS_TRIGGER" 
INSTEAD OF INSERT OR UPDATE OR DELETE ON MD_ORDER_ITEMS
--FOR EACH ROW
BEGIN
 
     IF inserting THEN   
         INSERT INTO s_item
         (ORD_ID, ITEM_ID, PRODUCT_ID, PRICE , QUANTITY , QUANTITY_SHIPPED)
         VALUES
        (:new.ORD_ID, :new.ITEM_ID, :new.PRODUCT_ID, :new.PRICE , :new.QUANTITY , :new.QUANTITY);
         sb.print('INSERTED ITEM');
     END IF; 
    
      IF updating ('QUANTITY') THEN
         UPDATE s_item 
              SET  QUANTITY = :new.QUANTITY,
                   QUANTITY_SHIPPED=:new.QUANTITY
             WHERE ORD_ID=:new.ORD_ID 
               AND PRODUCT_ID=:new.PRODUCT_ID;
          sb.print('UPDATED-'||:new.PRODUCT_ID);       
      END IF; 

       IF deleting THEN  
          DELETE FROM s_item
          WHERE ORD_ID=:old.ord_id
            AND ITEM_ID=:old.item_id
            AND PRODUCT_ID=:old.product_id;
          sb.print('DELETED');  
      END IF;
END;
/
ALTER TRIGGER "MD_ORDER_ITEMS_TRIGGER" ENABLE;
--------------------------------------------------------
--  DDL for Package MD_AUXNAVIGATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE "MD_AUXNAVIGATION" is
  v_searchKey_nr     number;
  function leaf      return varchar2;
  function collapsed return varchar2;
  function expanded  return varchar2;

  procedure expandByCountry;
  procedure expandBySalesRep;
  procedure expandTree;
  procedure leftClickTree;
  procedure displayTabContent;
  
end;

/
--------------------------------------------------------
--  DDL for Package MD_AWXCOMMITROLLBACK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE "MD_AWXCOMMITROLLBACK" is 
  procedure doCommit;
  procedure doRollback;
  procedure closeViolation;
end;

/
--------------------------------------------------------
--  DDL for Package MD_CUSTOMER
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE "MD_CUSTOMER" is
  procedure populateCustomer;
  procedure populateCustomerData(v_tabKey_tx varchar2);

  procedure clickOrdersGrid;
  procedure newOrder;
  procedure customerShippedDate;
  procedure editOrder;
  procedure saveOrder;
  procedure deleteOrder;
 
  procedure refreshrow;
  procedure detachGrid;
  procedure closeDetachGrid;

end;

/
--------------------------------------------------------
--  DDL for Package MD_GLOBAL
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE "MD_GLOBAL" is
       v_ordID_nr  number;
       v_itemID_nr number;
       procedure postInitialValues;
       procedure paymentType;
end;

/
--------------------------------------------------------
--  DDL for Package MD_ORDER
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE "MD_ORDER" is 
  procedure getOrderItems;
  procedure getItemInventory;
  procedure getItemImage;
  procedure getOrderInfo;
  procedure printToExcel;

  procedure newOrderItem;
  procedure orderShippedDate;
  procedure newItemTotal;
  procedure saveOrderItems ;
  procedure deleteOrderItem;
  
  procedure resetSession;
  procedure focusGridQuantity;
end;

/
--------------------------------------------------------
--  DDL for Package MD_SEARCH
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE "MD_SEARCH" is
  procedure searchSalesRep;
  procedure clearSearchNameCity;
  procedure searchNameCity;
  procedure showSearchResult;
  procedure detachSearch;
  procedure detachSearchCancel;
  procedure detachSearchOk;
end;

/
--------------------------------------------------------
--  DDL for Package MD_VIEWPOPUPMENU
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE "MD_VIEWPOPUPMENU" AS
procedure showAll;
procedure manageColumns;
procedure listColumns;
procedure detachGrid;
procedure sortColumns;
procedure reorderColumns;
END;

/
--------------------------------------------------------
--  DDL for Package SB
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE "SB" is 
/* Package that drives status bar function in meridian demo application */
 procedure print(printString varchar2);
 procedure clear;
END SB;

/
--------------------------------------------------------
--  DDL for Package Body MD_AUXNAVIGATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "MD_AUXNAVIGATION" is
--------------------------------------------------------------------------------
function leaf return varchar2 is
begin
  return api_treeNode.leaf;
end;
--------------------------------------------------------------------------------
function collapsed return varchar2 is
begin
  return api_treeNode.collapsed;
end;
--------------------------------------------------------------------------------
function expanded return varchar2 is
begin
  return api_treeNode.expanded;
end;
--------------------------------------------------------------------------------
procedure expandByCountry is
          v_treeName_tx varchar2(255) :='aux_sMNavTreeBrowse.mainPageTree';
begin
     --set seesion variable
          v_searchKey_nr := api_datasource.getid('aux_navigationTree1');
          api_session.add('expandByButton',v_searchKey_nr);
     --expand top node
          api_treenode.populatechildren(v_treeName_tx,'COUNTRIES', 'aux_navigationCountries1');
          api_treenode.expand(v_treeName_tx,'COUNTRIES');
end;
--------------------------------------------------------------------------------
procedure expandBySalesRep is
          v_treeName_tx varchar2(255) :='aux_sMNavTreeBrowse.mainPageTree';
begin
       --set session variable
          v_searchKey_nr := api_datasource.getid('aux_navigationSRTree1');
          api_session.add('expandByButton',v_searchKey_nr);
    
      --expand top node
          api_treenode.populatechildren(v_treeName_tx,'COUNTRIES','aux_navigationSRTree1');
          api_treenode.expand(v_treeName_tx,'COUNTRIES');
end;
--------------------------------------------------------------------------------

procedure expandTree is
          v_treeName_tx  varchar2(255) :='aux_sMNavTreeBrowse.mainPageTree';
          v_nodeKey_tx   varchar2(255);
          v_country_id   number;
          v_emp_id       number;
  
begin
          v_nodeKey_tx := api_tree.getexpandednodekey('aux_sMNavTreeBrowse.mainPageTree');
         api_debug.log(v_nodekey_tx);
      -- top node
          if (v_nodeKey_tx = 'COUNTRIES') then
            --do nothing as top node already populated by either expandbySalesRep
            --or expandByCountry
              NULL;
          else
      --check for tree selection criteria ---set back datasource??
             if (api_session.getvaluenr('expandByButton') = api_datasource.getid('aux_navigationTree1')) then
      --by country get counrty_id using country_code
                v_country_id:=api_datasource.getcolumnvaluetxbypk('aux_navigationCountries1.country_id',v_nodeKey_tx); 
                api_datasource.setbindvar(in_datasourcedotbindvar_tx=>'aux_navigationCustomers1.countryID',
	                                                                          in_value_nr=>v_country_id);
                api_treenode.populatechildren(v_treeName_tx,v_nodekey_tx, 'aux_navigationCustomers1'); 
     
            else
     --by sales_rep_id get emp_id using userid
                v_emp_id :=api_datasource.getcolumnvaluetxbypk('aux_navigationSRTree1.emp_id',v_nodeKey_tx); 
                api_datasource.setbindvar(in_datasourcedotbindvar_tx=>'aux_navigationSRCustomers1.salesRepID', 
		                                                                   in_value_nr=>v_emp_id);
                api_treenode.populatechildren(v_treeName_tx,v_nodekey_tx, 'aux_navigationSRCustomers1');  
            end if;
          end if;
end;
--------------------------------------------------------------------------------
procedure leftClickTree is
          v_treeName_tx         varchar2(255) :='aux_sMNavTreeBrowse.mainPageTree';
          v_nodeKey_tx          varchar2(255);
          v_newTabOrder_nr      number;
          v_existingTabOrder_nr number;
          v_nodeState_cd        varchar2(255);
          v_parentNode_tx       varchar2(10);
          v_country_id          number;
          v_emp_id              number;  
          v_exception_t         api_exception.t_exception;
  
begin
  
  ---remove all tabs.Uncomment this line if you want only one customer tab to 
  ---display when tree is leftclicked.
      ---api_tabbedpanel.removealltabs('aux_sMmainWorkAreaTabs');
  
  ----set current tab to customer info tab
     api_tabbedpanel.setcurrenttab('awx_localWorkAreaTabs','customer_infoPanel');
  ---set some inital session values to be used by datasources
  ---when inserting new orders or items
     MD_GLOBAL.POSTINITIALVALUES();
  
     v_nodeKey_tx    := api_tree.getselectednodekey('aux_sMNavTreeBrowse.mainPageTree');
     v_nodeState_cd  := api_treenode.getstate('aux_sMNavTreeBrowse.mainPageTree', v_nodeKey_tx);
     v_parentNode_tx := api_treenode.getparentnodekey('aux_sMNavTreeBrowse.mainPageTree', v_nodeKey_tx);
 
     if (v_nodeState_cd = leaf and v_parentNode_tx !='COUNTRIES') then -- meridian node
       begin
      -- if meridian tab is already added, set it as current tab     
       v_existingTabOrder_nr := api_tabbedpanel.gettaborder('aux_sMmainWorkAreaTabs', 'tab'||v_nodeKey_tx);
       api_tabbedpanel.setcurrenttab('aux_sMmainWorkAreaTabs', v_existingTabOrder_nr);
      --and display customer content
        api_tabbedpanel.settabpanel('aux_sMmainWorkAreaTabs','tab'||v_nodeKey_tx,'awx_localWorkArea');
      
       exception
         when api_exception.e_invalidTabName then -- meridian tab does not exist, add it
        -- get order of the tab to be added
            v_newTabOrder_nr := nvl(api_session.getvaluenr('tabOrder_nr'), 1) + 1;
            api_session.add('tabOrder_nr', v_newTabOrder_nr);
        -- add tab
            api_tabbedpanel.addtab(in_tabbedpanelname_tx => 'aux_sMmainWorkAreaTabs'
                              ,in_order_nr           => v_newTabOrder_nr
                              ,in_tabname_tx         => 'tab'||v_nodeKey_tx
                              ,in_title_tx           => api_treenode.getdisplay(v_treeName_tx, v_nodeKey_tx)
                              ,in_panelname_tx       => 'awx_localWorkArea'
                              ,in_closable_yn        => 'Y'
                              ,in_visible_yn         => 'Y'
                              ,in_enabled_yn         => 'Y'
                              );
         ---create session variable holding nodeKey values to be used later 
         ---to enable display of data when tab is clicked
            api_session.add('tab'||v_nodeKey_tx,v_nodeKey_tx);
         -- set the added tab as the current tab
            api_tabbedpanel.setcurrenttab('aux_sMmainWorkAreaTabs', v_newTabOrder_nr);
       end;              
  ---print to statusbar
            sb.print('Customer:'||v_nodeKey_tx);
  -- collapsed meridian folder node
     elsif (v_nodeState_cd = collapsed and v_parentNode_tx = 'COUNTRIES') then
         -- if this node is not expanded before, populate its child nodes
       if api_treenode.isprevexpanded(v_treeName_tx, v_nodeKey_tx) = 'N' then
          --check for tree selection criteria 
         if (api_session.getvaluenr('expandByButton') = api_datasource.getid('aux_navigationTree1')) then
          --by country get counrty_id using country_code
            v_country_id:=api_datasource.getcolumnvaluetxbypk('aux_navigationCountries1.country_id',v_nodeKey_tx); 
            api_datasource.setbindvar(in_datasourcedotbindvar_tx=>'aux_navigationCustomers1.countryID', in_value_nr=>v_country_id);
            api_treenode.populatechildren(v_treeName_tx,v_nodekey_tx, 'aux_navigationCustomers1'); 
         else
          --by sales_rep_id get emp_id using userid
            v_emp_id :=api_datasource.getcolumnvaluetxbypk('aux_navigationSRTree1.emp_id',v_nodeKey_tx); 
            api_datasource.setbindvar(in_datasourcedotbindvar_tx=>'aux_navigationSRCustomers1.salesRepID', in_value_nr=>v_emp_id);
            api_treenode.populatechildren(v_treeName_tx,v_nodekey_tx, 'aux_navigationSRCustomers1');  
         end if;
    -- expand the left clicked node
      api_treenode.expand('aux_sMNavTreeBrowse.mainPageTree', v_nodeKey_tx);
       end if;
   end if;
   
     --v_exception_t :=api_exception.getexception();
     --api_debug.log(v_exception_t.message_tx);
     
  ---REFRESH datasources each time customer is clicked
  ---this is here because the aux_sMNavTreeBrowse panel
  ---leftclick event is in use by this procedure 
  --and anyway we want to check what type of node is clicked
  if (v_parentNode_tx !='COUNTRIES') then
     MD_CUSTOMER.POPULATECUSTOMER();
  end if;
end;
--------------------------------------------------------------------------------
---called when a customer tab is clicked
procedure displayTabContent is
          v_tabName_tx         varchar2(255) :=api_tabbedpanel.getcurrenttabname('aux_sMmainWorkAreaTabs');
          v_currentTabOrder_nr number;
begin
 
          if (v_tabName_tx = 'aux_sMmainWorkAreaTabs') then  --if title page then do nothing
             sb.print('Main Work Area');
         else
      --if meridian tab is already added, set it as current tab      
             v_currentTabOrder_nr := api_tabbedpanel.gettaborder('aux_sMmainWorkAreaTabs',v_tabName_tx);
             api_tabbedpanel.setcurrenttab('aux_sMmainWorkAreaTabs',v_currentTabOrder_nr);
            api_tabbedpanel.settabpanel('aux_sMmainWorkAreaTabs',v_tabName_tx,'awx_localWorkArea');
        
      ---clear violation warnings
             MD_AWXCOMMITROLLBACK.closeViolation();
          
     ---for getting data for the specific customer
     ---to populate the current tab on display
     ---similar to  md_customer.populatecustomer() procedure
     ---but to avoid multiple code pathways with its attendant debugging
     ---complications we provide this procedure for use only by displayTabContent
             MD_CUSTOMER.POPULATECUSTOMERDATA(api_session.getvaluetx(to_char(v_tabName_tx)));
         end if;
end;
--------------------------------------------------------------------------------
END;

/
--------------------------------------------------------
--  DDL for Package Body MD_AWXCOMMITROLLBACK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "MD_AWXCOMMITROLLBACK" is 
--------------------------------------------------------------------------------
procedure doCommit is
begin
      ---call appropriate procedures to save datasource entries
          MD_ORDER.saveOrderItems;
          MD_CUSTOMER.saveOrder;
        
end;
--------------------------------------------------------------------------------

procedure doRollback is
begin
---- calls to procedures
        --refresh order grid
          MD_CUSTOMER.refreshRow;
        --refresh order item grid.call the clickOrdersgrid procedure
          MD_CUSTOMER.clickOrdersGrid;
        ---reset temp ordID used when creating new orders
          MD_ORDER.resetSession;                         
end;

--------------------------------------------------------------------------------
procedure closeViolation is
begin
          api_panel.setvisible('violation_panel','N');
end;
--------------------------------------------------------------------------------

END;

/
--------------------------------------------------------
--  DDL for Package Body MD_CUSTOMER
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "MD_CUSTOMER" is
--------------------------------------------------------------------------------
procedure populateCustomer is
          v_tree_tx       varchar2(255) :='aux_sMNavTreeBrowse.mainPageTree';
          v_nodeKey_tx    varchar2(255);
          v_parentNode_tx varchar(10);
          v_country_id    number;
begin
        
    	 --get customer node   
          v_nodeKey_tx:= api_tree.getselectednodekey(v_tree_tx); 
        --check if node key is actually a customer code .right now just skipping to exception
          v_parentNode_tx:=api_treenode.getparentnodekey(v_tree_tx,v_nodekey_tx);
        
       if (v_parentNode_tx != 'COUNTRIES') then     ---skip parent nodes
        -- get country_id  
           execute immediate 'select country_id from S_CUSTOMER 
                   where id='||v_nodeKey_tx||'' into v_country_id;

        --get customer information
         api_datasource.setBindvar('CUSTOMER1.countryID',in_value_nr=>v_country_id);
         api_datasource.setBindvar('CUSTOMER1.customerID',in_value_tx=>v_nodeKey_tx);
         api_datasource.executeQuery('CUSTOMER1');

       ---get customer orders 
         api_datasource.setBindvar('CUSTOMER_ORDERS1.customerID',in_value_nr=>v_nodeKey_tx);
         api_datasource.executeQuery('CUSTOMER_ORDERS1');
    
       ---chart datasource
         api_datasource.setBindvar('CHARTDS1.customer_id',in_value_nr=>v_nodeKey_tx);
         api_datasource.executeQuery('CHARTDS1');
    
       --set sales rep name
         api_datasource.setBindvar('EMPLOYEES1.id',api_component.getValueNR('customer_generalPanel.salesRepId'));
         api_datasource.executeQuery('EMPLOYEES1');
    
    ---get order items info of current order in orders grid 
          MD_ORDER.getOrderInfo();
     /*
       --set the tab title back to "Orders"
         --api_tabbedpanel.settabtitle('awx_localWorkAreaTabs','order_infoPanel','Order ');
       ---REFERESH CHARTS
          if(api_datasource.getcurrentrowid('CHARTDS1') is not null) then
             api_chart.refresh('dashBoard_historyPanel.orderHistory');
             api_chart.refresh('dashBoard_shippingPanel.orderShipping');
             api_chart.refresh('dashBoard_proportionPanel.orderProportion');
          
          end if;
          */    
     end if;
     EXCEPTION
      WHEN NO_DATA_FOUND THEN
      NULL; 
    
end;
--------------------------------------------------------------------------------
procedure populateCustomerData(v_tabKey_tx varchar2) is
          v_tree_tx    varchar2(255) :='aux_sMNavTreeBrowse.mainPageTree';
          v_nodeKey_tx varchar2(255);
          v_country_id number;
begin

          v_nodeKey_tx:= v_tabKey_tx; --customer ID
        
       ---depending on tab key  get country id
      ---check if node key is actually a customer code?? .right now just skipping to exception       
          execute immediate 'select country_id from S_CUSTOMER where id='||v_nodeKey_tx||'' into v_country_id;
 
    --get customer information
          api_datasource.setBindvar('CUSTOMER1.countryID',in_value_nr=>v_country_id);
          api_datasource.setBindvar('CUSTOMER1.customerID',in_value_tx=>v_nodeKey_tx);
          api_datasource.executeQuery('CUSTOMER1');
   
    ---get customer orders 
          api_datasource.setBindvar('CUSTOMER_ORDERS1.customerID',in_value_nr=>v_nodeKey_tx);
          api_datasource.executeQuery('CUSTOMER_ORDERS1');
  ---chart datasource
          api_datasource.setBindvar('CHARTDS1.customer_id',in_value_nr=>v_nodeKey_tx);
          api_datasource.executeQuery('CHARTDS1');
    
    --set sales rep name
          api_datasource.setBindvar('EMPLOYEES1.id',api_component.getValueNR('customer_generalPanel.salesRepId'));
          api_datasource.executeQuery('EMPLOYEES1');
        
     ---get order items info of current order in orders grid 
          MD_ORDER.getOrderInfo();

     ---REFERESH CHARTS
          api_chart.refresh('dashBoard_historyPanel.orderHistory');
          api_chart.refresh('dashBoard_shippingPanel.orderShipping');
          api_chart.refresh('dashBoard_proportionPanel.orderProportion');
     
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
      NULL;
end;
--------------------------------------------------------------------------------
procedure clickOrdersGrid is
begin
      --set focus to orders tab ...maybe
         --api_tabbedpanel.setcurrenttab('awx_localWorkAreaTabs','order_infoPanel');

      --set sales rep name--perharps do seperate datasource???
        api_datasource.setBindvar('EMPLOYEES1.id',api_component.getValueNR('order_infoPanel.salesRepId'));
        api_datasource.executeQuery('EMPLOYEES1');
      ---get order items info of current order in orders grid 
        MD_ORDER.getOrderInfo();
end;
--------------------------------------------------------------------------------

procedure newOrder is
          v_customerID_nr  number;   
          rowid_1          number;
          rowid_2          number;
          v_rows_t         api_datasource.tt_rows;
          v_tempcount_nr   number:=0;
begin
    ---check if there are any new orders with status New 
    --- if any alert user to complete pending order in grid
          api_datasource.getRows('CUSTOMER_ORDERS1',v_rows_t);
          for i in 1..v_rows_t.count loop
              if (v_rows_t(i)('DS_ROWSTATUS').value_tx ='New') then
                  v_tempcount_nr :=v_tempcount_nr +1;
              end if;
          end loop;
        
    if (v_tempcount_nr=0) then
        v_customerID_nr :=api_datasource.getcolumnvaluenr('CUSTOMER1.ID');
  --clear current contents of form datasources
        api_datasource.clear('ORDER_ITEMS1','ClearCurrent');
        api_datasource.clear('INVENTORY1','ClearCurrent');
     
      --set focus to orders tab ??
      --api_tabbedpanel.setcurrenttab('awx_localWorkAreaTabs','order_infoPanel');

      ---enter order in customer orders grid    
        rowid_1:=api_datasource.createrow('CUSTOMER_ORDERS1',NULL,NULL);
        rowid_2 :=api_datasource.createrow('ORDER_ITEMS1',NULL,NULL);
 
        api_datasource.setcurrentrow('CUSTOMER_ORDERS1',rowid_1);
        api_datasource.setcurrentrow('ORDER_ITEMS1',rowid_2);

     ---set customer id
        api_datasource.setColumnValue('CUSTOMER_ORDERS1.CUSTOMER_ID',v_customerID_nr,rowid_1);
    
     --set order ID via session variable initialized in MD_GLOBAL.postInitialValues
        api_session.add('ordID',api_session.getvaluenr('ordID')-1);
        api_datasource.setcolumnvalue('CUSTOMER_ORDERS1.ID',api_session.getvaluenr('ordID')); 
      
     --default values
        api_datasource.setcolumnvalue('CUSTOMER_ORDERS1.DATE_ORDERED',TO_DATE(SYSDATE));
        api_datasource.setcolumnvalue('CUSTOMER_ORDERS1.TOTAL',0);
        api_datasource.setcolumnvalue('CUSTOMER_ORDERS1.PAYMENT_TYPE','CASH');
        api_datasource.setcolumnvalue('CUSTOMER_ORDERS1.PAYMENT_TYPE_ID',1);
        api_datasource.setcolumnvalue('CUSTOMER_ORDERS1.ORDER_FILLED','N');
        api_datasource.setcolumnvalue('CUSTOMER_ORDERS1.SALES_REP_ID',api_datasource.getcolumnvaluetx('EMPLOYEES1.ID'));
        api_datasource.setcolumnvalue('CUSTOMER_ORDERS1.LAST_NAME',api_component.getValueTX('customer_generalPanel.lastName'));
    else 
        sb.print('Commit pending order');
    end if;
end;
--------------------------------------------------------------------------------
procedure customerShippedDate is
          gridShipDate  DATE :=to_date(api_component.getvaluedt('customer_ordersGrid.dateShipped'));
          gridOrderDate  DATE :=to_date(api_component.getvaluedt('customer_ordersGrid.dateOrdered'));
begin
           if (api_component.isfocused('customer_ordersGrid.ordersGrid','N')='Y') then
            if (gridShipDate< gridOrderDate) then
                api_application.showpopupmessage('You cannot have a shipping date that is before the order date');
                if (api_session.getvaluedt('shippedDate') is null) then
                  --defaulting to current date
                   api_component.setvalue('customer_ordersGrid.dateShipped',TO_DATE(SYSDATE));
                else
                    api_datasource.setcolumnvalue('CUSTOMER_ORDERS1.date_shipped',api_session.getvaluedt('shippedDate'));
                end if;
            end if;
        end if;  

end;
--------------------------------------------------------------------------------
procedure editOrder is
begin
     --set focus to orders tab
          api_tabbedpanel.setcurrenttab('awx_localWorkAreaTabs','order_infoPanel');
          clickOrdersGrid();
end;     
--------------------------------------------------------------------------------

procedure saveOrder is
          v_ordID_nr  number;
begin   
     ---check status of row(s) and assign order number   
     ---order ID
       CASE api_datasource.getrowstatus('CUSTOMER_ORDERS1') 
           WHEN 'New' THEN
            select s_ord_id.nextval into v_ordID_nr from dual;
              api_datasource.setcolumnvalue('CUSTOMER_ORDERS1.ID',v_ordID_nr); 
              api_datasource.docommit('CUSTOMER_ORDERS1');
              api_component.setValue('customer_ordersGrid.ID',v_ordID_nr);
           WHEN 'Updated' THEN
             api_datasource.docommit('CUSTOMER_ORDERS1');
           WHEN 'Deleted' THEN
             api_datasource.docommit('CUSTOMER_ORDERS1');
             ELSE
             NULL;
        END CASE;
        
         --if no row ignore the thrown error
        EXCEPTION
        WHEN api_exception.e_noCurrentRow THEN
        NULL;
end;
--------------------------------------------------------------------------------
procedure deleteOrder is
          v_currentRowID_nr number;
          v_orderID_nr      number;
          v_numberOrders_nr number;
begin
          v_currentRowID_nr := api_datasource.getCurrentRowID('CUSTOMER_ORDERS1'); 
          v_orderID_nr :=api_datasource.getColumnValuenr('CUSTOMER_ORDERS1.ID',v_currentRowID_nr);
    --check if order has items.Delete if no items
          execute immediate 'select count(*) from S_ITEM where ord_id='||v_orderID_nr||'' into v_numberOrders_nr;  
          if (v_currentRowID_nr is not null and v_numberOrders_nr =0) then
              api_datasource.deleteCurrentRow('CUSTOMER_ORDERS1');
         --commit
              api_datasource.docommit('CUSTOMER_ORDERS1');
         else
              sb.print('Order has '||v_numberOrders_nr||' items');
         end if;
  --if no row ignore the thrown error
        EXCEPTION
        WHEN api_exception.e_noCurrentRow THEN
           sb.print('Choose order to delete');
end;
--------------------------------------------------------------------------------
procedure refreshRow is
begin
          api_datasource.refreshrow('CUSTOMER_ORDERS1');
end;
--------------------------------------------------------------------------------
procedure detachGrid is
begin
          api_dialog.setvisible('customer_ordersGridDetach','Y');
end;
procedure closeDetachGrid is
begin
          api_dialog.setvisible('customer_ordersGridDetach','N');
end;
--------------------------------------------------------------------------------

END;

/
--------------------------------------------------------
--  DDL for Package Body MD_GLOBAL
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "MD_GLOBAL" is
--------------------------------------------------------------------------------
procedure postInitialValues is
begin
    --these variables are used to assigning temporary 
    --ID numbers to new orders and items
    --called by the lefClickTree procedure
        v_ordID_nr:=0;
        v_itemID_nr:=0;
        api_session.add('ordID',v_ordID_nr);
        api_session.add('itemID',v_itemID_nr);
end;
--------------------------------------------------------------------------------
procedure paymentType is
begin
     ---check credit rating
        if (api_datasource.getcolumnvalueNR('CUSTOMER1.CREDIT_RATING_ID') in (3,4)) 
           and (api_component.getValueNR('order_infoPanel.paymentType')=2
           or  api_component.getValueNR('customer_ordersGrid.paymentType')=2) then
          ---display warning
            api_application.showpopupmessage('Cannot change payment type to credit');
          --revert to cash
            api_component.setValue('order_infoPanel.paymentType',1);
        else
            api_datasource.setcolumnvalue('CUSTOMER_ORDERS1.PAYMENT_TYPE_ID',
                        api_component.getValueNR('order_infoPanel.paymentType'));
        end if;
   
end;
--------------------------------------------------------------------------------
END;

/
--------------------------------------------------------
--  DDL for Package Body MD_ORDER
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "MD_ORDER" is
--------------------------------------------------------------------------------
procedure getOrderItems is
          v_orderId_nr     number;  
          v_total_nr       number;
begin
    ---get selected order id 
          v_orderId_nr := api_datasource.getcolumnvaluenr('CUSTOMER_ORDERS1.id'); 
       ---print to status bar
          sb.print(v_orderId_nr);
    ---get original date shipped
          api_session.add('shippedDate',api_datasource.getcolumnvaluedt('CUSTOMER_ORDERS1.date_shipped'));
    --populate items belonging to selected order
          api_datasource.setBindvar('ORDER_ITEMS1.ordID',v_orderId_nr);
          api_datasource.executeQuery('ORDER_ITEMS1');
    --set the tab title to show order number
          api_tabbedpanel.settabtitle('awx_localWorkAreaTabs','order_infoPanel','Order '||v_orderId_nr);
     --sum total price of items
          execute immediate 'select sum(PRICE*QUANTITY_SHIPPED) from ('
                      ||api_datasource.getquery('ORDER_ITEMS1')||')' into v_total_nr;
          api_component.setValue('order_infoPanel.totalPrice',v_total_nr);
    
     ---clear violation warnings
          Md_AWXCOMMITROLLBACK.closeViolation();
     ---if no items
     ---where its a new order ignore the no current row error from items datasource
    EXCEPTION
     WHEN api_exception.e_noCurrentRow THEN
          api_tabbedpanel.settabtitle('awx_localWorkAreaTabs','order_infoPanel','Order '||v_orderId_nr);
end;
--------------------------------------------------------------------------------
procedure getItemInventory is
          v_productId_nr number;
begin
     ---get selected product_id 
          v_productId_nr := api_datasource.getColumnValueNR('ORDER_ITEMS1.product_id');
          api_datasource.setBindvar('INVENTORY1.product_id',v_productId_nr);
          api_datasource.executeQuery('INVENTORY1');
    --get item image
          getItemImage();
    ---where its a new order ignore the no current row error from items datasource
    EXCEPTION
     WHEN api_exception.e_noCurrentRow THEN
      NULL;
end;
--------------------------------------------------------------------------------
procedure getItemImage is
          v_imagePath_tx varchar2(255);
          v_productId_nr number;
begin
   ---get image path and set component order_imagepanel.image url
          v_productId_nr := api_datasource.getColumnValueNR('ORDER_ITEMS1.product_id');
          v_imagePath_tx :='apps/meridianDemo/images/products/'||GET_PRODUCT_IMAGE(v_productId_nr);    
          api_component.setUrl('order_imagePanel.image',v_imagePath_tx);
end;
--------------------------------------------------------------------------------
procedure getOrderInfo is
begin
    --Called by the following
    --MD_CUSTOMER.populateCustomerData
    --MD_CUSTOMER.populateCustomerData(v_tabKey_tx varchar2)
    --MD_CUSTOMER.clickOrdersGrid
    --MD_SEARCH.showSearchResult
    --awx_localWorkAreaTabs panel ---> PostTabChanged event
    
         ---clear order items grid
         api_datasource.clear('ORDER_ITEMS1','ClearAll');
         ---clear order items locations grids
         api_datasource.clear('INVENTORY1','ClearAll');
         --clear image
         api_component.setUrl('order_imagePanel.image','');
           --get info
          getOrderItems();
          getItemInventory(); 
          
          ---REFERESH CHARTS
          if (api_datasource.getcolumnvaluedt('CHARTDS1.DATE_SHIPPED') is not NULL) then
              api_chart.refresh('dashBoard_historyPanel.orderHistory');
              api_chart.refresh('dashBoard_shippingPanel.orderShipping');
              api_chart.refresh('dashBoard_proportionPanel.orderProportion');
          end if;
          
            --if no row ignore the thrown error
        EXCEPTION
        WHEN api_exception.e_noCurrentRow THEN
        NULL;  
        WHEN NO_DATA_FOUND THEN
        NULL;
end;
--------------------------------------------------------------------------------
procedure printToExcel is
begin
     api_component.printToExcel(in_panelDotComponentName_tx => 'order_infoPanel.orderItemsGrid'
                            ,in_usepaging_yn             => 'N'
                            ,in_filename_tx              => 'Excel_Output_From_Grid'
                            ,in_fileformat_cd            => api_component.FILE_FORMAT_XLS);
end;

--------------------------------------------------------------------------------
procedure newOrderItem is
          v_rows_t        api_datasource.tt_rows;
          v_tempcount_nr  number:=0;
          v_ordID_nr      number;
          v_row_id        number;
          v_productID_nr  number;
begin
       ---check if there are any item lines with status New 
       ---if any alert user to complete pending item in grid
          api_datasource.getRows('ORDER_ITEMS1',v_rows_t);
          for i in 1..v_rows_t.count loop
            if (v_rows_t(i)('DS_ROWSTATUS').value_tx ='New') then
            v_tempcount_nr :=v_tempcount_nr +1;
            end if;
          end loop;
        
    if (v_tempcount_nr=0) then
          v_row_id :=api_datasource.createrow('ORDER_ITEMS1');
          api_datasource.setcurrentrow('ORDER_ITEMS1',v_row_id);
    ---order ID
          v_ordID_nr :=api_datasource.getColumnValueNR('CUSTOMER_ORDERS1.ID');
          api_datasource.setcolumnvalue('ORDER_ITEMS1.ORD_ID',v_ordID_nr);
      
    ---set temp itemID via session variable initialized MD_GLOBAL.postInitialValues
          api_session.add('itemID',api_session.getvaluenr('itemID')-1);
          api_datasource.setcolumnvalue('ORDER_ITEMS1.ITEM_ID',api_session.getvaluenr('itemID'));
     
    ---focus in on product id
        api_component.requestFocus('order_infoPanel.productID');   
    else
        sb.print('Commit pending order');
    end if;
  
end;
--------------------------------------------------------------------------------
 procedure orderShippedDate is
           shipDate  date :=to_date(api_component.getvaluedt('order_infoPanel.dateShipped'));
           orderDate date :=to_date(api_component.getvaluedt('order_infoPanel.dateOrdered'));
begin   
        if (api_component.isfocused('order_infoPanel.dateShipped','N')= 'Y') then
           if (shipDate < orderDate) then
               --warning popup and set to current date if null
                 api_application.showpopupmessage('You cannot have a shipping date that is before the order date');
                 if (api_session.getvaluedt('shippedDate') is NULL) then
                 --defaulting to current date
                   api_component.setvalue('order_infoPanel.dateShipped',TO_DATE(SYSDATE)); 
                 else
                   api_component.setvalue('order_infoPanel.dateShipped',api_session.getvaluedt('shippedDate'));
                 end if;
           end if;
        end if;
end;        
--------------------------------------------------------------------------------
procedure newItemTotal is
          v_quantity_nr   number;
          v_price_nr      number;
          v_total_nr      number;
          v_orderTotal_nr number:=0;
          v_rows_t        api_datasource.tt_rows;
begin     
      ---line item total
      v_quantity_nr :=api_component.getValueNR('order_infoPanel.itemQuantity');
      v_price_nr    :=api_component.getValueNR('order_infoPanel.itemPrice');
      v_total_nr    :=((v_quantity_nr*v_price_nr)); 
      api_datasource.setcolumnvalue('ORDER_ITEMS1.TOTAL',v_total_nr);

       ---sum total price amount of items
      api_datasource.getRows('ORDER_ITEMS1',v_rows_t);
       for i in 1..v_rows_t.count loop
          ---deal with nulls
           if((v_rows_t(i)('TOTAL').value_nr) is NULL)then
              v_rows_t(i)('TOTAL').value_nr :=0;
            --  api_component.requestfocus('order_infoPanel.itemQuantity');
           else
             v_orderTotal_nr:=v_rows_t(i)('TOTAL').value_nr + v_orderTotal_nr;
           end if;
       end loop;
       ---set datasource value only after all validation is done
      api_datasource.setcolumnvalue('CUSTOMER_ORDERS1.TOTAL',to_number(v_orderTotal_nr)); 
      api_component.setValue('order_infoPanel.totalPrice',to_number(v_orderTotal_nr));  
end;
--------------------------------------------------------------------------------
procedure saveOrderItems is
          v_ordID_nr      number;
          v_itemID_nr     number;
          v_violations_tt api_datasource.tt_requiredcolumnviolation;
          v_rows_t        api_datasource.tt_rows;
          v_text_tt       varchar2(1000);
begin

     ---check for column violations and quantity value       
        v_violations_tt := api_datasource.getrequiredcolumnviolations('ORDER_ITEMS1');                
        if(v_violations_tt.count = 0) then
    ---clear warnings
          MD_AWXCOMMITROLLBACK.closeViolation;   
    ---loop through the order item grid and act accordingly
          api_datasource.getRows('ORDER_ITEMS1',v_rows_t);
          for i in 1..v_rows_t.count loop
            if (v_rows_t(i)('DS_ROWSTATUS').value_tx ='New') then
             --if adding new item to existing order which has not shipped
                if (v_ordID_nr is NULL) then
                    v_ordID_nr := api_datasource.getcolumnvaluenr('CUSTOMER_ORDERS1.ID');
                end if; 
                api_datasource.setcolumnvalue('ORDER_ITEMS1.ORD_ID',v_ordID_nr);
              --set item ID
                select s_item_id.nextval into v_itemID_nr from dual;
              --set current column value by rowid
                api_datasource.setcolumnvalue('ORDER_ITEMS1.ITEM_ID',v_itemID_nr);   
           end if;
          end loop;
          --commit
          api_datasource.docommit('ORDER_ITEMS1');
       else
             ---warn user of required fields missing values
              for i in 1..v_violations_tt.count loop
                 v_text_tt :=v_text_tt||('row id : ' || v_violations_tt(i).row_id)||': ';
                  for j in 1..v_violations_tt(i).columns_t.count loop
                  v_text_tt:=v_text_tt||( v_violations_tt(i).columns_t(j).name_tx)||' ,';
                   end loop;
                   v_text_tt:=v_text_tt||' required'||chr(10);
              end loop;
              ---check 
             api_panel.setvisible('violation_panel','Y');
             api_component.setlabel('violation_panel.violations',v_text_tt);
             api_panel.addpanel('order_infoPanel','violation','violation_panel');
      end if;
      
    ---where its a new order ignore the no current row error from items datasource
      EXCEPTION
       WHEN api_exception.e_noCurrentRow THEN
       NULL;
       
end;
---------------------------------------------------------------------------------
procedure deleteOrderItem is
          v_currentRowID_nr number;
          v_productID_nr    number;
          v_orderTotal_nr   number:=0;
          v_rows_t          api_datasource.tt_rows;

begin
      v_currentRowID_nr := api_datasource.getCurrentRowID('ORDER_ITEMS1');
      v_productID_nr :=api_datasource.getColumnValuenr('ORDER_ITEMS1.PRODUCT_ID',v_currentRowID_nr);

    ---you can check other condition like if item has already shipped
      if (v_currentRowID_nr is not null) then
    ---set focus on row
         api_component.requestFocus('order_infoPanel.dateOrdered'); 
         sb.print('Item '||v_productID_nr||' deleting');
         api_datasource.deleteCurrentRow('ORDER_ITEMS1');
        --clear order items locations grids
         api_datasource.clear('INVENTORY1','ClearCurrent');      
      end if;
    
      --update totals
      --sum total price amount of items
        api_datasource.getRows('ORDER_ITEMS1',v_rows_t);
        for i in 1..v_rows_t.count loop
            v_orderTotal_nr:=v_rows_t(i)('TOTAL').value_nr + v_orderTotal_nr;
        end loop;
        api_datasource.setcolumnvalue('CUSTOMER_ORDERS1.TOTAL',to_number(v_orderTotal_nr)); 
        api_component.setValue('order_infoPanel.totalPrice',to_number(v_orderTotal_nr)); 
      
      --if no row ignore the thrown error
      EXCEPTION
      WHEN api_exception.e_noCurrentRow THEN
           sb.print('Choose item to delete');
end;
--------------------------------------------------------------------------------
procedure resetSession is
begin
     ---reset temp  itemID via session variable initialized MD_GLOBAL.postInitialValues
         api_session.add('itemID',0); 
end;
--------------------------------------------------------------------------------
procedure focusGridQuantity is
begin
         ---used by order_lovSearchProduct on close event  to place cursor 
         ---in quantity field in order_infoPanel.orderItemsGrid
         api_component.requestfocus('order_infoPanel.itemQuantity');
end;

--------------------------------------------------------------------------------

END;

/
--------------------------------------------------------
--  DDL for Package Body MD_SEARCH
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "MD_SEARCH" is
--------------------------------------------------------------------------------
procedure searchSalesRep is
begin
         api_lov.show('customer_lovSalesRep');
end;
-------------------------------------------------------------------------------
procedure clearSearchNameCity is
begin
         api_component.setValue('aux_sMNavTreeSearch.txtName','');
         api_component.setValue('aux_sMNavTreeSearch.txtCity',''); 
      ---clear search results grid
         api_datasource.clear('SEARCHDS1','ClearAll');
end;
--------------------------------------------------------------------------------
procedure searchNameCity is
          v_name_tx varchar2(20);
          v_city_tx varchar2(20);
begin
      v_name_tx :=to_char(api_component.getValueTx('aux_sMNavTreeSearch.txtName'));
      v_city_tx :=to_char(api_component.getValueTx('aux_sMNavTreeSearch.txtCity'));
  
   --check if fields have values
       if v_name_tx is not null then
         api_datasource.setBindvar('SEARCHDS1.name',in_value_tx=>v_name_tx);
       else
         api_datasource.setBindvar('SEARCHDS1.name',in_value_tx=>'%');
       end if;
      
       if v_city_tx is not null then
          api_datasource.setBindvar('SEARCHDS1.city',in_value_tx=>v_city_tx);
       else
          api_datasource.setBindvar('SEARCHDS1.city',in_value_tx=>'%');
       end if;
       api_datasource.executeQuery('SEARCHDS1');

    EXCEPTION
      WHEN api_exception.e_noCurrentRow THEN
     api_application.showpopupmessage(v_name_tx);
end;

-------------------------------------------------------------------------------
procedure showSearchResult is
          v_existingTabOrder_nr number;
          v_newTabOrder_nr      number;
          v_customer_tx         varchar2(20);
          v_customerName_tx     varchar2(255);
          v_country_id          number;
          v_salesRepId          number;
begin
     
    v_customer_tx :=to_char(api_datasource.getcolumnvaluenr('SEARCHDS1.id',api_datasource.getcurrentrowid('SEARCHDS1')));
    v_customerName_tx :=api_datasource.getcolumnvaluetx('SEARCHDS1.name',api_datasource.getcurrentrowid('SEARCHDS1'));
    v_country_id  :=to_number(api_datasource.getcolumnvaluetx('SEARCHDS1.country_id',api_datasource.getcurrentrowid('SEARCHDS1')));
    v_salesRepid  :=to_number(api_datasource.getcolumnvaluetx('SEARCHDS1.sales_rep_id',api_datasource.getcurrentrowid('SEARCHDS1')));

 ---clear violation warnings
    MD_AWXCOMMITROLLBACK.closeViolation();
                
    if (v_customer_tx is not null) then
       begin
         ---check if tab for customer is already addedd
            v_existingTabOrder_nr := api_tabbedpanel.gettaborder('aux_sMmainWorkAreaTabs', 'tab'||v_customer_tx);

            api_tabbedpanel.setcurrenttab('aux_sMmainWorkAreaTabs', v_existingTabOrder_nr);
          --and display tab
            api_tabbedpanel.settabpanel('aux_sMmainWorkAreaTabs','tab'||v_customer_tx,'awx_localWorkArea');
            
           ---create new tab
           exception
             when api_exception.e_invalidTabName then
                v_newTabOrder_nr := nvl(api_session.getvaluenr('tabOrder_nr'), 1) + 1;
                api_session.add('tabOrder_nr', v_newTabOrder_nr);
              -- add tab
              api_tabbedpanel.addtab(in_tabbedpanelname_tx => 'aux_sMmainWorkAreaTabs'
                              ,in_order_nr           => v_newTabOrder_nr
                              ,in_tabname_tx         => 'tab'||v_customer_tx
                              ,in_title_tx           => v_customer_tx||'-'||v_customerName_tx
                              ,in_panelname_tx       => 'awx_localWorkArea'
                              ,in_closable_yn        => 'Y'
                              ,in_visible_yn         => 'Y'
                              ,in_enabled_yn         => 'Y'
                              );
         ---create session variable holding nodeKey values to be used later 
         ---to enable display of data when tab is clicked
            api_session.add('tab'||v_customer_tx,v_customer_tx);
         -- set the added tab as the current tab
            api_tabbedpanel.setcurrenttab('aux_sMmainWorkAreaTabs',v_newTabOrder_nr);
         --api_debug.log(api_session.getvaluetx('tab'||v_customer_tx));            
      end;
    end if;
    
     --customer information and orders data
            api_datasource.setbindvar('CUSTOMER1.customerID', v_customer_tx);
            api_datasource.setbindvar('CUSTOMER1.countryID', v_country_id);
            api_datasource.setbindvar('CUSTOMER_ORDERS1.customerID', to_number(v_customer_tx));
     
            api_datasource.executeQuery('CUSTOMER1');
            api_datasource.executeQuery('CUSTOMER_ORDERS1');
     
       ---chart datasource
            api_datasource.setBindvar('CHARTDS1.customer_id',to_number(v_customer_tx));
            api_datasource.executeQuery('CHARTDS1');
    
    --set sales rep name
            api_datasource.setBindvar('EMPLOYEES1.id',v_salesRepId);
            api_datasource.executeQuery('EMPLOYEES1');
    
      ---clear order items and iventory grid
            api_datasource.clear('ORDER_ITEMS1','ClearAll');
            api_datasource.clear('INVENTORY1','ClearAll');
         
     ---get order items info of current order in orders grid 
            MD_ORDER.getOrderInfo();
     ---REFERESH CHARTS
            api_chart.refresh('dashBoard_historyPanel.orderHistory');
            api_chart.refresh('dashBoard_shippingPanel.orderShipping');
            api_chart.refresh('dashBoard_proportionPanel.orderProportion');
end;

-------------------------------------------------------------------------------
procedure detachSearch is
begin
          api_dialog.setvisible('customer_citySearchDetach','Y');
end;
--------------------------------------------------------------------------------
procedure detachSearchCancel is
begin
          api_dialog.setvisible('customer_citySearchDetach','N');
end;
--------------------------------------------------------------------------------
procedure detachSearchOk is
begin
          api_dialog.setvisible('customer_citySearchDetach','N');
end;
--------------------------------------------------------------------------------
END;

/
--------------------------------------------------------
--  DDL for Package Body SB
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SB" is
--------------------------------------------------------------------------------
procedure print(printString varchar2) is
begin
          api_component.setValue('aux_statusBarPanel.st',printString);
end;
--------------------------------------------------------------------------------
procedure clear is
begin
         api_component.setValue('aux_statusBarPanel.st','');
end;
--------------------------------------------------------------------------------
END SB;

/
