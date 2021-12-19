import { KeyElement} from "../types/parsesTongue"

export function KeyParser(PK:string, SK:string)
{
    if(SK.startsWith(PK))
    {
        let attr = SK.split('#')
        let Element: KeyElement = {archetype:attr[0], id: attr[1]};
        Element.access = attr[2]
        Element.bridge = attr[3]
        return Element
    }
    else{
        let attrPK = PK.split('#')
        let attrSK = SK.split('#')
        let Element: KeyElement = {archetype: attrPK[0] + attrSK[0], id: attrSK[1], relation: attrPK[1]};
        Element.access = attrSK[2]
        Element.bridge = attrSK[3]
        return Element
    }
    // else
    //     {
    //         let relation = SK.split('#')
    //         let entity = PK.split('#')
    //         let Element: KeyElement = {archetype:entity[0]+relation[0], id: entity[1], relationid: relation[1]}

    //     }
}
