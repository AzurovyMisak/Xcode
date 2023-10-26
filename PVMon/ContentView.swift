//
//  ContentView.swift
//  PVMon
//
//  Created by Sysprobs on 10/26/23.
//

import SwiftUI
import CocoaMQTT
import SwiftyJSON


let konstatnty = "kokot"

struct ContentView: View {
    
    @State public var debugMessage: String = "ZATIM NIC"
    @State public var isMqttConnected: Bool = false
    @State public var txtPVPower: String = "0 W"
    @State public var txtPVVoltage: String = "0 V"
    @State public var txtPVCurrent: String = "0 A"
    
    @State private var txtHomePowerTotal: String = "0 W"
    @State private var txtHomePowerL1: String = "0 W"
    @State private var txtHomePowerL2: String = "0 W"
    @State private var txtHomePowerL3: String = "0 W"
    
    @State private var txtBatSOC: String = "0 %"
    @State private var txtBatPower: String = "0 W"
    @State private var txtBatSOH: String = "0 %"
    @State private var txtBatVoltage: String = "0 V"
    @State private var txtBatCurrent: String = "0 A"
    @State private var batCharge: Double = 0.0
    @State private var imgBatState: String = "arrow-stop"
    
    @State private var imgGridL1State: String = "arrow-stop"
    @State private var imgGridL2State: String = "arrow-stop"
    @State private var imgGridL3State: String = "arrow-stop"
    @State private var txtGridL1: String = "0 W"
    @State private var txtGridL2: String = "0 W"
    @State private var txtGridL3: String = "0 W"
    @State private var txtGridIn: String = "0 W"
    @State private var txtGridOut: String = "0 W"
    
    
    
    @State private var animFlash = false
        
    
    let mqttclient = CocoaMQTT(
        clientID: "swiftui",
        host: "broker.hivemq.com",
        port: 1883)
    
    init() {
        // sem dej inicializaci MQTT
        self.mqttclient.keepAlive = 60
        self.mqttclient.autoReconnect = true
    }
    
    private func animLiveOprationFlash() {
        self.animFlash.toggle()
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(0), execute: {
            withAnimation(.easeIn(duration: 5)) {
                self.animFlash.toggle()
            }
        })
        
    }
    
    func fnParsujZpravu(topic: String, msg: String) {
        
        debugMessage = topic
        
        switch topic {
        case "misakpecky/solar/data":
            self.animLiveOprationFlash()
        
            if let data = msg.data(using: .utf8) {
                if let json = try? JSON(data: data) {
                    let PVPower = json["Power_PV1"].doubleValue + json["Power_PV2"].doubleValue
                    let PVVoltage = json["Voltage_PV1"].doubleValue + json["Voltage_PV2"].doubleValue
                    let PVCurrent = json["Current_PV1"].doubleValue + json["Current_PV2"].doubleValue
                    txtPVPower = fnDejKilo(value: PVPower, units: "W")
                    txtPVVoltage = fnDejKilo(value: PVVoltage, units: "V")
                    txtPVCurrent = fnDejKilo(value: PVCurrent, units: "A")
                    txtHomePowerTotal = fnDejKilo(value: json["Load_Power_Total"].doubleValue,units: "W")
                    txtHomePowerL1 = fnDejKilo(value: json["Load_Power_L1"].doubleValue, units: "W")
                    txtHomePowerL2 = fnDejKilo(value: json["Load_Power_L2"].doubleValue, units: "W")
                    txtHomePowerL3 = fnDejKilo(value: json["Load_Power_L3"].doubleValue, units: "W")
                    
                    txtBatVoltage = fnDejKilo(value: json["Battery_U"].doubleValue, units: "V")
                    txtBatCurrent = fnDejKilo(value: abs(json["Battery_I"].doubleValue), units: "A")
                    let batP = json["Battery_P"].doubleValue
                    txtBatPower = fnDejKilo(value: abs(batP), units: "W")
                    self.imgBatState = "arrow-right"
                    if (abs(batP) > 50) {
                        if (batP > 0) {
                            // baterka se vybiji, sipka doprava
                            self.imgBatState = "arrow-right"
                        } else {
                            self.imgBatState = "arrow-left"
                            // baterka se vybiji, sipka doleva
                        }
                        
                    }else {
                        // baterka nic nedela, smaz obrazek
                        self.imgBatState = "arrow-stop"
                    }
                    batCharge = json["Battery_SOC"].doubleValue
                    txtBatSOC = String(json["Battery_SOC"].intValue) + " %"
                    
                    
                    let gridPowerL1 = json["MT_Active_Power_L1"].intValue
                    let gridPowerL2 = json["MT_Active_Power_L2"].intValue
                    let gridPowerL3 = json["MT_Active_Power_L3"].intValue
                    
                    txtGridL1 = fnDejKilo(value: abs(Double(gridPowerL1)), units: "W")
                    txtGridL2 = fnDejKilo(value: abs(Double(gridPowerL2)), units: "W")
                    txtGridL3 = fnDejKilo(value: abs(Double(gridPowerL3)), units: "W")
                    
                    imgGridL1State = gridPowerL1 >= 0 ? "arrow-right" : "arrow-left"
                    imgGridL2State = gridPowerL2 >= 0 ? "arrow-right" : "arrow-left"
                    imgGridL3State = gridPowerL3 >= 0 ? "arrow-right" : "arrow-left"
                    
                    var nZaporny = 0
                    var nKladny = 0
                    
                    if (gridPowerL1 > 0) {
                        nKladny += gridPowerL1
                    } else {
                        nZaporny += abs(gridPowerL1)
                    }
                    
                    if (gridPowerL2 > 0) {
                        nKladny += gridPowerL2
                    } else {
                        nZaporny += abs(gridPowerL2)
                    }
                    
                    if (gridPowerL3 > 0) {
                        nKladny += gridPowerL3
                    } else {
                        nZaporny += abs(gridPowerL3)
                    }
                    
                    txtGridOut = fnDejKilo(value: Double(nZaporny), units: "W")
                    txtGridIn = fnDejKilo(value: Double(nKladny), units: "W")
                }
            }
        default: break
        }
    }
    
    func fnDejKilo(value: Double, units: String) -> String {
        var retval = ""
        if (value <= 999) {
            retval = String(format: "%.0f", value) + " " + units
        } else {
            retval = String(format: "%.2f",value / 1000.0) + " k" + units
            //retval = String(format: "%.2f", (round(value / 1000))) + " k" + units
        }
        return retval
    }
    
    var body: some View {
        
        ZStack{
            Color("theme_gray_9")
            VStack(alignment: .leading) {
                
                /* // Prni radek tlacitko na pripojeni
                 HStack() {
                    Button(action: {
                        if (!isMqttConnected) {
                            _ = mqttclient.connect()
                            self.mqttclient.didConnectAck = { mqtt, ack in
                                self.isMqttConnected.toggle()
                                self.mqttclient.subscribe("misakpecky/solar/data")
                                self.mqttclient.didReceiveMessage = {mqtt, message, id in
                                    if (message.string != nil) {
                                        fnParsujZpravu(msg: message.string!)
                                    }
                                }
                            }

                        } else {
                            self.mqttclient.disconnect()
                            self.isMqttConnected.toggle()
                        }
                    }, label: {
                        Text(isMqttConnected ? "Disconnect" : "Connect")
                    })
                }.frame(maxWidth: .infinity, maxHeight: 30, alignment: .trailing)
                */ // end prvni radek tlacitko na pripojeni
 
 
                //Live Data Panel
                VStack(spacing: 10){
                    
                    HStack {//-Nadpis Live Date
                        RoundedRectangle(cornerRadius: 3.0)
                            .fill(animFlash ? Color("lightGreen") : Color("theme_gray_8"))
                            .frame(width: 15, height: 7, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                            .clipShape(RoundedRectangle(cornerRadius: 3.0))
                            //.border(Color("theme_gray_7"))
                        Text("Live operation")
                            .foregroundColor(Color("theme_gray_6"))
                            .fontWeight(.bold)
                            
                    }
                    HStack{//Radek PV+HOME
                        HStack{//Levy Horni panel
                            VStack(alignment: .leading, spacing: 5){
                            
                                Image("solar-panel")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(Color("fve_icon"))
                                .background(
                                    RadialGradient(gradient: Gradient(colors: [.white, Color("fve_icon")]), center: .center, startRadius: 1, endRadius: 60))
                                .clipShape(RoundedRectangle(cornerRadius: 5.0))
                            
                            }
                            VStack(alignment: .leading, spacing: 1){
                                Text(txtPVPower).fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(Color("txt_light_gray"))
                                Text(txtPVVoltage)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color("txt_light_gray"))
                                Text(txtPVCurrent)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color("txt_light_gray"))
                            }
                        }.frame(
                            width:UIScreen.main.bounds.width/2-40,
                            height: 100,
                            alignment: .leading)
                        .padding(.leading, 10)
                        .background(Color("theme_gray_6"))
                        .clipShape(RoundedRectangle(cornerRadius: 5.0))
                        //End Levy Horni Panel
                    
                        //Pravy Horni Panel
                        HStack{
                            VStack(alignment: .trailing, spacing: 1){
                                Text(txtHomePowerTotal).fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(Color("txt_light_gray"))
                                Text("L1: " + txtHomePowerL1).font(.system(size: 12)).foregroundColor(Color("txt_light_gray"))
                                Text("L2: " + txtHomePowerL2).font(.system(size: 12)).foregroundColor(Color("txt_light_gray"))
                                
                                Text("L3: " + txtHomePowerL3).font(.system(size: 12)).foregroundColor(Color("txt_light_gray"))
                            }
                            VStack {
                                Image("solar-home")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(Color("fve_icon"))
                                .background(
                                    RadialGradient(gradient: Gradient(colors: [.white, Color("fve_icon")]), center: .center, startRadius: 1, endRadius: 60))
                                .clipShape(RoundedRectangle(cornerRadius: 5.0))
                                
                            }
                        }.frame(width:UIScreen.main.bounds.width/2-40, height: 100, alignment: .trailing)
                        .padding(.trailing, 10)
                        .background(Color("theme_gray_6"))
                        .clipShape(RoundedRectangle(cornerRadius: 5.0))
                        //End Pravy Horni
                    }//End radek PV+HOME
                    
                    HStack{//**radek Bat+Grid
                        HStack(alignment: .top){//**HStack-Levy Dolni panel (BAT)
                            VStack(alignment: .center, spacing: 0){
                                ZStack {//**Obrazek baterky
                                    Image("solar-battery")
                                        .resizable()
                                        .frame(width: 60, height: 60)
                                        .foregroundColor(Color("fve_icon"))
                                        .background(
                                            RadialGradient(gradient: Gradient(colors: [.white, Color("fve_icon")]), center: .center, startRadius: 1, endRadius: 60))
                                        .clipShape(RoundedRectangle(cornerRadius: 5.0))
                                    
                                    //var batCharge = 97.0
                                    let batFill : Double = (35 / 100) * batCharge
                                    let batOffset : Double = batFill / 2
                                    
                                    Rectangle()
                                        .fill(Color("fve_icon"))
                                        .frame(width: 20, height: CGFloat(batFill), alignment: .bottom)
                                        .offset(x: 0, y: 20 - CGFloat(batOffset ))
                                }//**End-Zstack-obrazek baterky
                                
                                Text(txtBatPower).fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(Color("txt_light_gray"))
                                    .padding(.top, 4)
                                Text(txtBatSOC).fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(Color("txt_light_gray"))
                            }//.border(Color.blue)
                            
                            //** VStack-battery-SOH,A,V,direction image
                            VStack(alignment: .leading, spacing: 0){
                                VStack(alignment: .leading) {
                                    Text("SOH: " + txtBatSOH)
                                        .font(.system(size: 12))
                                        .foregroundColor(Color("txt_light_gray"))
                                    Text(txtBatVoltage)
                                        .font(.system(size: 12))
                                        .foregroundColor(Color("txt_light_gray"))
                                    Text(txtBatCurrent)
                                        .font(.system(size: 12))
                                        .foregroundColor(Color("txt_light_gray"))
                                }//.border(Color.pink)
                                Spacer()
                                HStack(){//**image-battery-direction
                                    Spacer()
                                    Image(self.imgBatState)
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(Color("fve_icon"))                                    //Text(">>")
                                }//.border(Color.green)
                                
                            }.padding(.leading, 5)
                            //.border(/*@START_MENU_TOKEN@*/Color.black/*@END_MENU_TOKEN@*/)
                            //**End-Vstack-battery-SOH,A,V,direction image
                            
                        }.frame(
                            width:UIScreen.main.bounds.width/2-50,
                            height: 106,
                            alignment: .topLeading)
                        .padding(10)
                        .background(Color("theme_gray_6"))
                        .clipShape(RoundedRectangle(cornerRadius: 5.0))
                        //.border(Color.red)
                        //**End-HStack-Levy Dolni Panel (BAT)
                        
                        
                        //**HStack-Pravy Dolni Panel (GRID)
                        VStack(alignment: .trailing, spacing: 0){
                            HStack(alignment: .top) {
                                //**VStack-Sloupecek Gridu L1-L3
                                VStack(alignment: .leading, spacing:-1){
                                    HStack(){
                                        Image(self.imgGridL1State)
                                            .resizable()
                                            .frame(width: 20, height: 20)
                                            .foregroundColor(Color("fve_icon"))
                                        
                                        Text(self.txtGridL1).font(.system(size: 12))
                                            .foregroundColor(Color("txt_light_gray"))
                                        
                                    }//.border(Color.pink)
                                    HStack(){
                                        Image(self.imgGridL2State)
                                            .resizable()
                                            .frame(width: 20, height: 20)
                                            .foregroundColor(Color("fve_icon"))
                                        Text(self.txtGridL2).font(.system(size: 12))
                                            .foregroundColor(Color("txt_light_gray"))
                                    
                                    }//.border(Color.black)
                                    HStack(){
                                        Image(self.imgGridL3State)
                                            .resizable()
                                            .frame(width: 20, height: 20)
                                            .foregroundColor(Color("fve_icon"))
                                        Text(self.txtGridL3).font(.system(size: 12))
                                            .foregroundColor(Color("txt_light_gray"))
                                    
                                    }//.border(Color.yellow)
                                }
                                //.border(Color.green)
                                //**End-VStack-Sloupecek Gridu L1-L3
                                //**VStack-Sloupecek s ikonou Gridu
                                VStack(alignment: .trailing, spacing: 0){
                                    Image("solar-grid")
                                        .resizable()
                                        .frame(width: 60, height: 60)
                                        .foregroundColor(Color("fve_icon"))
                                        .background(
                                            RadialGradient(gradient: Gradient(colors: [.white, Color("fve_icon")]), center: .center, startRadius: 1, endRadius: 60))
                                        .clipShape(RoundedRectangle(cornerRadius: 5.0))
                                }//.border(Color.orange)
                            //**End-VStack-Sloupcecek s ikonou Gridu
                            }//.border(Color.yellow)
                            //**VStack-Grid-Texty s dodavkou a odberem
                            VStack(alignment: .trailing, spacing: -10){
                                HStack(){
                                    Image("arrow-left")
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(Color("fve_icon"))
                                    Text(self.txtGridOut).fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(Color("txt_light_gray"))
                                    
                                }//.border(Color.blue)
                                
                                HStack(){
                                    Image("arrow-right")
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(Color("fve_icon"))
                                    Text(self.txtGridIn).fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(Color("txt_light_gray"))
                                    
                                }//.border(Color.blue)
                            }.frame(alignment: .trailing)
                            //.border(Color.purple)
                            //**END-Vstack-Grid-Texty s dodavkou a odberem
                            
                    }.frame(
                            width:UIScreen.main.bounds.width/2-50,
                            height: 106,
                            alignment: .topTrailing)
                        .padding(10)
                        .background(Color("theme_gray_6"))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        //.border(Color.red)
                        //**End-HStack-Pravy Dolni Panel (GRID)
                        
                    }//END HStack radek Bat+Grid
                    
                    
                    
                }.frame(width: UIScreen.main.bounds.width - 20, height: 290, alignment: .center)
                .background(Color("theme_gray_7"))
                .clipShape(RoundedRectangle(cornerRadius: 5.0))
                .padding(10)
                //.padding(.leading, 10)
                //.padding(.trailing, 10)
                //.border(Color.blue)
                //End Live Data Panel
            
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color("theme_gray_8"))
            .padding(0)
            .clipShape(RoundedRectangle(cornerRadius: 15.0))
            
            VStack() { // debug
                Text(self.debugMessage)
            }.frame(maxWidth: .infinity, maxHeight: 150, alignment: .topLeading)
 
        }.onAppear {
            if (!isMqttConnected) {
                _ = mqttclient.connect()
                self.mqttclient.didConnectAck = { mqtt, ack in
                    self.isMqttConnected.toggle()
                    self.mqttclient.subscribe("misakpecky/solar/data")
                    self.mqttclient.didReceiveMessage = {mqtt, message, id in
                        if (message.string != nil) {
                            fnParsujZpravu(topic: message.topic, msg: message.string!)
                        }
                    }
                }
            }
            
        }.onDisappear {
            self.mqttclient.disconnect()
            self.isMqttConnected.toggle()
        }
        
        
    }
    
}

/*
struct ContentView: View {
    var body: some View {
        Text("Hello, world!")
            .padding()
    }
}
*/

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
