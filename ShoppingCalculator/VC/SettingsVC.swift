import Eureka

final class SettingsVC: FormViewController {
    
    override func loadView() {
        super.loadView()
        title = NSLocalizedString("Settings", comment: "")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        form +++ Section(NSLocalizedString("CurrencySetting", comment: ""))
        
        <<< SwitchRow("useDeviceCurrency"){
            $0.title = NSLocalizedString("DeviceSettingCurrency", comment: "")
            $0.value = userSettingServiceSingleton.userSetting.useDeviceCurrency
            $0.onChange { row in
                userSettingServiceSingleton.userSetting.useDeviceCurrency = row.value!
            }
        }
        <<< PickerRow<String>("allCurrency") { (row: PickerRow<String>) -> Void in
            row.hidden = Condition.function(["useDeviceCurrency"], { form in
                return ((form.rowBy(tag: "useDeviceCurrency") as? SwitchRow)?.value ?? false)
            })
            row.options = []
            
            let locale = NSLocale.current as NSLocale
            for code in Locale.commonISOCurrencyCodes {
                guard let currencyName = locale.displayName(forKey: NSLocale.Key.currencyCode, value: code) else { continue }
                guard let currencySymbol = locale.displayName(forKey:NSLocale.Key.currencySymbol, value: code) else { continue }
                
                let value = "\(currencyName) \(currencySymbol)"
                row.options.append(value)
                
                if code == userSettingServiceSingleton.currencyCode {
                    row.value = value
                }
            }
            
            row.onChange { row in
                for code in Locale.commonISOCurrencyCodes {
                    guard let currencyName = locale.displayName(forKey: NSLocale.Key.currencyCode, value: code) else { continue }
                    guard let currencySymbol = locale.displayName(forKey:NSLocale.Key.currencySymbol, value: code) else { continue }
                    
                    let value = "\(currencyName) \(currencySymbol)"

                    if row.value == value {
                        userSettingServiceSingleton.userSetting.userCurrencyCode = code
                        break
                    }
                }
            }
        }
        
        +++ Section(NSLocalizedString("HistorySetting", comment: ""))
        <<< DoublePickerInlineRow<HistorySortColumn, HistorySortOrder>() {
            $0.title = NSLocalizedString("Sort", comment: "")
            $0.firstOptions = { () -> [HistorySortColumn] in
                return [
                    .createdAt,
                    .updatedAt,
                ]
            }
            $0.secondOptions = { (_) -> [HistorySortOrder] in
                return [
                    .acs,
                    .desc,
                ]
            }
            $0.value = .init(
                a: userSettingServiceSingleton.userSetting.sortColumn,
                b: userSettingServiceSingleton.userSetting.sortOrder
            )
            $0.onChange { row in
                let column = row.value!.a
                let order = row.value!.b
                
                userSettingServiceSingleton.userSetting.sortColumn = column
                userSettingServiceSingleton.userSetting.sortOrder = order
                
                let notificaiton = Notification(
                    name: .HistorySettingChanged,
                    object: self,
                    userInfo: [
                        "column": column,
                        "order": order,
                    ]
                )
                NotificationCenter.default.post(notificaiton)
            }
        }
        
//        let continents = ["Africa", "Antarctica", "Asia", "Australia", "Europe", "North America", "South America"]
//        for option in continents {
//            form.last! <<< ListCheckRow<String>(option){ listRow in
//                listRow.title = option
//                listRow.selectableValue = option
//                listRow.value = nil
//            }
//        }
//
//        form.last!
        
//        <<< TextRow(){ row in
//            row.title = "Text Row"
//            row.placeholder = "Enter text here"
//        }
//        <<< PhoneRow(){
//            $0.title = "Phone Row"
//            $0.placeholder = "And numbers here"
//        }
//        +++ Section("Section2")
//        <<< DateRow(){
//            $0.title = "Date Row"
//            $0.value = Date(timeIntervalSinceReferenceDate: 0)
//        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        userSettingServiceSingleton.saveToUserDefault()
    }
}
