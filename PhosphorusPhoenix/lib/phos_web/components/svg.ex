defmodule PhosWeb.SVG do
  use Phoenix.Component

  def logo(%{type: "banner"} = assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class={@class}
      viewBox="0 0 5038.22 902.01">
      <title>Scratchbac Banner</title>
      <g id="Layer_2" data-name="Layer 2">
        <g id="Layer_1-2" data-name="Layer 1">
          <path d="M145.42,740.57c-11.48,0-23.78-.41-36.71-1.42-22.35-1.74-48.49-6-72.85-24.23A116.33,116.33,0,0,1,5.11,680.19,37.5,37.5,0,1,1,69.9,642.42,41.56,41.56,0,0,0,80.84,654.9c8.54,6.4,18.82,8.32,33.69,9.48,56.16,4.37,98.54-4.75,99-4.84,13.52-3,36.3-8.17,57.88-15,8-2.55,14.48-4.91,19.73-7-11.79-6.37-26.59-13.62-39.66-20a453.72,453.72,0,0,0-41.9-18c-5.54-2.12-11.26-4.32-17.39-6.88-33.67-14-112.54-46.9-157.68-120.67-10.59-17.31-42.83-70-31.68-140.09,8.48-53.37,40.45-101.39,90-135.21,7.82-5.34,28.61-19.53,54.12-29.45,47.13-18.34,79.6-9.81,98.53.57,40.1,22,50.86,66.47,56.64,90.37,6.92,28.6,5,51.07,2.07,85.07A569.68,569.68,0,0,1,293,416.52a37.5,37.5,0,0,1-73.25-16.12,494.09,494.09,0,0,0,9.69-63.69c2.7-31.51,3.64-44.94-.25-61-3.27-13.53-8.75-36.18-19.79-42.23-9.62-5.28-34.86-1.88-74.32,25.06-32.8,22.38-52.94,51.79-58.22,85-6.8,42.78,13.82,76.48,21.58,89.16,32.46,53,93.32,78.41,122.57,90.6,5.15,2.15,10.14,4.06,15.42,6.09,12.61,4.84,26.9,10.33,48,20.7,25.53,12.52,45.7,22.41,61,32.32,9.39,6.11,38,24.69,37.61,56.86-.16,13.6-5.69,33.45-31.12,50.85-10.93,7.47-25,14.29-43.12,20.85-29,10.51-61.47,17.82-78.93,21.75C228.14,733.12,194.35,740.56,145.42,740.57Z"/><path d="M560.87,681.46c-23.71,0-61-3.74-95.83-29.85C438.7,631.87,406,593.1,399.51,520.47c-3.93-44.26,7.65-77.45,14.57-97.28,19.42-55.67,51.38-88.93,66.73-104.91a313.38,313.38,0,0,1,85.09-62.81,37.5,37.5,0,1,1,33.76,67,238.7,238.7,0,0,0-64.77,47.81c-12.57,13.08-36,37.43-50,77.64-5.56,15.94-13.17,37.78-10.67,65.94C477.43,550,489.48,576.2,510,591.6c21.8,16.34,47.05,15.22,62.13,14.54,42.12-1.87,73.47-25.67,88.41-39.69a37.5,37.5,0,1,1,51.33,54.69c-22.5,21.12-70.14,57-136.41,59.93C571.56,681.24,566.61,681.46,560.87,681.46Z"/><path d="M2146.62,681.28c-23.7,0-61-3.74-95.83-29.86-26.33-19.73-59.07-58.51-65.52-131.14-3.93-44.25,7.65-77.45,14.57-97.28,19.42-55.67,51.37-88.92,66.73-104.91a313.4,313.4,0,0,1,85.09-62.8,37.5,37.5,0,0,1,33.76,67,238.46,238.46,0,0,0-64.77,47.8c-12.57,13.08-36,37.43-50,77.65-5.56,15.94-13.18,37.77-10.67,65.94,3.21,36.2,15.26,62.36,35.8,77.76,21.8,16.34,47,15.22,62.13,14.55,42.12-1.88,73.47-25.67,88.41-39.69A37.5,37.5,0,0,1,2297.65,621c-22.51,21.12-70.15,57-136.41,59.93C2157.32,681.06,2152.37,681.28,2146.62,681.28Z"/><path d="M3781.55,680.82c-23.7,0-61-3.75-95.83-29.86-26.33-19.74-59.08-58.51-65.53-131.14-3.92-44.26,7.66-77.45,14.57-97.28,19.42-55.67,51.38-88.93,66.74-104.91a313.18,313.18,0,0,1,85.08-62.81,37.5,37.5,0,0,1,33.77,67,238.4,238.4,0,0,0-64.77,47.81c-12.57,13.08-36,37.43-50,77.64-5.56,15.95-13.18,37.78-10.68,66,3.22,36.2,15.26,62.36,35.8,77.76,21.8,16.34,47.05,15.22,62.14,14.55,42.12-1.88,73.47-25.68,88.4-39.7a37.5,37.5,0,1,1,51.33,54.69c-22.5,21.12-70.14,57-136.4,59.93C3792.25,680.6,3787.3,680.82,3781.55,680.82Z"/><path d="M829.13,744.67a37.52,37.52,0,0,1-36.31-28.24,1112.86,1112.86,0,0,1-26.51-407.15,37.5,37.5,0,0,1,16.07-26.5,366,366,0,0,1,90.21-45c32.91-11,58.52-16.45,76.12-16.13l4,.07c34.44.58,70.07,1.18,118.59,34.88,17,11.82,29.73,26,37.79,42.25a37.6,37.6,0,0,1,3.38,10.4l.37.86a71.36,71.36,0,0,1,4.23,12.12,128.38,128.38,0,0,1,2.86,40.16c-6.38,72.5-90.16,158.68-214.39,171.52a285.07,285.07,0,0,1-68.12-1.2A1036.74,1036.74,0,0,0,865.5,697.89a37.56,37.56,0,0,1-36.37,46.78ZM833.5,456a211.58,211.58,0,0,0,64.29,3.31c92.92-9.6,144.57-71.52,147.39-103.48a53.33,53.33,0,0,0-.9-15.18c-.15-.37-.33-.78-.48-1.13a86.3,86.3,0,0,1-3.92-10.62,46.08,46.08,0,0,0-11.39-10.68c-29.81-20.7-46.6-21-77.09-21.5l-4.06-.07c-5-.09-21.45,2.39-50.93,12.26a288.51,288.51,0,0,0-57.57,26.69A1045.29,1045.29,0,0,0,833.5,456ZM1113,316.76v0Z"/><path d="M1031.9,674.13a225.89,225.89,0,0,1-73.58-12.69c-31.82-10.93-57.1-26.71-72.2-36.13C838.91,595.85,798.61,553,769.59,501.4A37.5,37.5,0,0,1,835,464.63c22.88,40.67,54.3,74.23,90.87,97C952.3,578.2,1001.57,609,1060.58,596c36-7.89,62.56-29,78.56-45.26a37.5,37.5,0,1,1,53.52,52.53c-33.17,33.8-73.29,56.62-116,66A209,209,0,0,1,1031.9,674.13Z"/><path d="M1288.62,739.71a37.51,37.51,0,0,1-37.11-32.4,825.39,825.39,0,0,1-.62-223.71c8.34-61.18,22.6-114.1,42.39-157.29,18.76-41,41.68-70.59,66.27-85.7,31.47-19.34,62.22-19.24,65.63-19.16,5.13.11,32.08,1.56,59.88,18.85,36.31,22.58,65,72.31,87.68,152,8.06,28.32,13.72,55.06,17,72.5,1.69,8.83,4.26,22.83,5.32,31.38h0a1183.06,1183.06,0,0,1,13.42,151.25A37.49,37.49,0,0,1,1572,685.86h-.94a37.49,37.49,0,0,1-37.47-36.57A1107.5,1107.5,0,0,0,1521,507.66l-.09-.6a789.17,789.17,0,0,0-20.57-95c-23.86-83.41-48.07-103.8-54.92-108.06a54,54,0,0,0-21.9-7.52,56.4,56.4,0,0,0-24.74,8c-8.78,5.4-23.2,22.16-37.35,53-16.48,36-29,83.06-36.25,136.17a749.71,749.71,0,0,0,.6,203.37,37.56,37.56,0,0,1-37.19,42.62Z"/><path d="M1401.7,543.4A758.36,758.36,0,0,1,1283,534.05,37.5,37.5,0,1,1,1294.76,460a683.12,683.12,0,0,0,130,8,685.22,685.22,0,0,0,123.43-15.58,37.5,37.5,0,0,1,16.12,73.25,758.83,758.83,0,0,1-137,17.28Q1414.55,543.41,1401.7,543.4Z"/><path d="M3259.23,740.32a37.5,37.5,0,0,1-37.1-32.41,828.73,828.73,0,0,1-.6-224.22c8.33-61.31,22.59-114.35,42.38-157.64,18.76-41,41.67-70.74,66.26-85.88,31.51-19.41,62.26-19.3,65.68-19.22,5.12.11,32.09,1.56,59.9,18.9,36.3,22.63,65,72.46,87.64,152.34,8.06,28.38,13.72,55.18,17.05,72.66,1.68,8.85,4.25,22.9,5.31,31.45h0a1190.35,1190.35,0,0,1,13.41,151.6,37.5,37.5,0,0,1-75,1.85,1115.11,1115.11,0,0,0-12.55-142l-.09-.56h0A793.59,793.59,0,0,0,3471,411.87c-23.86-83.66-48.08-104.1-54.94-108.37a54.1,54.1,0,0,0-21.86-7.54A56.3,56.3,0,0,0,3369.5,304c-8.79,5.41-23.22,22.23-37.38,53.2-16.49,36.08-29,83.3-36.27,136.56a753.81,753.81,0,0,0,.58,203.93,37.49,37.49,0,0,1-32,42.25A39.09,39.09,0,0,1,3259.23,740.32Z"/><path d="M3372.29,543.4A756.56,756.56,0,0,1,3253.64,534,37.5,37.5,0,1,1,3265.41,460a682.1,682.1,0,0,0,130,8,683.27,683.27,0,0,0,123.42-15.62A37.5,37.5,0,0,1,3535,525.63,757.34,757.34,0,0,1,3398,543Q3385.18,543.41,3372.29,543.4Z"/><path d="M1649.57,377.16a37.5,37.5,0,0,1-3.78-74.81,1137.8,1137.8,0,0,0,152-26.13A1137.14,1137.14,0,0,0,1961.5,223,37.5,37.5,0,1,1,1990,292.32a1212.78,1212.78,0,0,1-174.57,56.78,1213.59,1213.59,0,0,1-162,27.86C1652.14,377.09,1650.85,377.16,1649.57,377.16Z"/><path d="M1821.31,744.65a55.14,55.14,0,0,1-15.62-2.24c-29.22-8.64-39.1-38.55-44-60.3-8-35.44-11.66-92.93-11.25-175.75.31-62.55,3-125.54,7.86-187.21a37.5,37.5,0,1,1,74.76,6c-4.75,59.82-7.32,120.93-7.62,181.63-.41,82.89,3.7,126.64,7.5,149.27,1.87-2,3.91-4.39,6.12-7a37.5,37.5,0,0,1,57.69,47.93c-15.3,18.42-29.33,31.06-42.88,38.65C1841.59,742.41,1830.52,744.64,1821.31,744.65Zm17.63-65.84h0Z"/><path d="M2407.22,746.13a37.5,37.5,0,0,1-37.12-32.49c-8.07-59.88-14.5-120.77-19.11-181-7-91.21-10-183.88-9-275.42a37.5,37.5,0,1,1,75,.83c-1,89.36,2,179.83,8.78,268.87,4.5,58.79,10.77,118.23,18.66,176.69a37.52,37.52,0,0,1-37.21,42.51Z"/><path d="M2680.88,681.71a37.5,37.5,0,0,1-37.16-32.8c-6-47.39-10.68-95.57-13.95-143.22-4.91-71.73-6.75-144.57-5.47-216.5a37.51,37.51,0,0,1,37.48-36.83h.69a37.5,37.5,0,0,1,36.82,38.17c-1.25,69.78.54,140.45,5.31,210,3.16,46.22,7.72,93,13.53,138.93a37.51,37.51,0,0,1-32.5,41.91A38.35,38.35,0,0,1,2680.88,681.71Z"/><path d="M2494.87,557.45a449.81,449.81,0,0,1-118.48-15.92,37.5,37.5,0,0,1,19.74-72.36A374.1,374.1,0,0,0,2649.66,449a37.5,37.5,0,0,1,30.83,68.37,449.52,449.52,0,0,1-173.22,40Q2501.07,557.44,2494.87,557.45Z"/><path d="M2936,746.13a426.3,426.3,0,0,1-121.09-17.85A37.51,37.51,0,0,1,2788,693.67l-6.51-181.19c-.06-.37-.11-.73-.16-1.11a38.16,38.16,0,0,1-.18-8.33l-8.25-229.9a37.48,37.48,0,0,1,12.23-29.07,327.06,327.06,0,0,1,74.8-51.18c16.34-8.09,46.74-23.17,81.38-31.36,48.45-11.45,88.85-5.63,120.1,17.31,24,17.59,40.58,44,48,76.41,14.62,63.42-20.44,114.71-39.27,142.26-21.54,31.51-48.11,56.56-76.33,76.46,2.89.36,5.77.75,8.65,1.14,29.74,4.08,74.38,13,118.45,43.47,29.56,20.43,45.88,41.75,51.35,67.09,5.06,23.45.62,47.9-13.21,72.66-21,37.67-61.49,63.65-120.24,77.21-42,9.69-81.68,10.31-96.63,10.54Q2939.11,746.13,2936,746.13ZM2862,663a344.73,344.73,0,0,0,79.11,8.08c113.81-1.77,144.59-35.08,152.55-49.33,1.92-3.44,7-12.59,5.38-20.27-1.12-5.17-8.65-12.9-20.68-21.2-34.44-23.8-71.9-28.94-86-30.88a838.16,838.16,0,0,0-134.7-7.21Zm-13.45-374.45,6.11,170.08c50.85-15.76,114.42-46.05,153.65-103.45,14.08-20.59,35.34-51.71,28.11-83.1-4.26-18.5-12.87-28-19.34-32.79-33-24.23-101.33,9.65-123.78,20.79A250,250,0,0,0,2848.54,288.56Z"/><path d="M5002.22,677.65A36,36,0,0,1,4969,655.46c-8.92-21.43-17.79-43-26.38-63.82-43.41-105.34-84.41-204.85-137.61-311-28.91-53.5-58.27-101.63-84.94-139.21-34.44-48.55-49.87-59.08-51.51-60.12-13.31-8.42-25.09-9.24-27-9.32a36,36,0,0,0-12.79,3.06c-4.09,2.64-6.22,7.4-6.95,9-5,11.27,1.48,24.53,2.24,26a36,36,0,1,1-64,33c-5.46-10.6-21.9-48.29-4-88.38,10.77-24.09,27.11-36.84,38.93-43.3.65-.35,1.3-.68,2-1A108,108,0,0,1,4640.11,0c3.41-.09,34.12-.29,66.92,20.47,44,27.85,112.32,135.23,161.56,226.44.17.32.34.64.5,1,54.52,108.7,96.07,209.55,140.07,316.32,8.56,20.79,17.42,42.28,26.29,63.61a36,36,0,0,1-33.23,49.83ZM4642.05,72h0Z"/><path d="M4647.24,257.94a36,36,0,0,1-33.31-22.32,283.63,283.63,0,0,0-14.1-29.37c-.42-.75-3.83-6.76-7.48-12.72-46.58-76-81.42-98.42-98.05-105-7.07-2.8-11.89-3.64-16.65-2.92-.12,0-13.81,2.3-20.4,12.45a28.81,28.81,0,0,0-4.46,11c-2.41,14.68,9.88,28.9,11.29,30.47a36,36,0,1,1-53.61,48.05c-8.63-9.63-36.21-44.59-28.73-90.18a100.17,100.17,0,0,1,15.13-38.52c23.19-35.7,62.38-43.26,70-44.41,23.22-3.52,41.9,2.4,53.92,7.16,44.37,17.55,89.1,62.75,133,134.34,4.61,7.52,8.71,14.82,8.89,15.13l.11.19a355.85,355.85,0,0,1,17.77,37,36,36,0,0,1-33.28,49.7Z"/><path d="M4537.14,340.2a36,36,0,0,1-31.47-18.47c-10.67-19.13-22.32-38.14-34.6-56.49-12-17.94-20.68-30.9-33.42-46.3-22.33-27-47.63-57.56-78.67-63.11-4.53-.81-11-1.44-16.33.14-9,2.69-15.51,9.88-18.36,15.22-6.34,11.91-2.73,29.86,8.78,43.65A36,36,0,1,1,4277.78,261a122.17,122.17,0,0,1-27.31-59.54c-3.5-22.74.06-44.89,10.28-64.07,12.7-23.85,35.6-42.68,61.26-50.36,15.14-4.53,31.84-5.22,49.64-2,57,10.2,94.27,55.22,121.47,88.09,15.07,18.21,25.6,33.94,37.78,52.15,13.37,20,26,40.64,37.65,61.46a36,36,0,0,1-31.41,53.55Z"/><path d="M4345.9,626.7a36,36,0,0,1-33.51-22.84,692.35,692.35,0,0,0-33.31-73c-6-11.3-11.9-21.25-12.54-22.35-9.32-15.8-17.59-28.15-23.64-37.16-14.73-22-29.56-41.86-42.64-59.39-35.24-47.23-63.07-84.53-64-128.07a120.46,120.46,0,0,1,10-50.47,104.89,104.89,0,0,1,37-43c.45-.3.9-.59,1.36-.87,3.19-2,32.15-19.11,65.7-17.4l.38,0c.84,0,5.27.35,10.06,1.13,27.74,4.47,57.92,24.35,92.28,60.76a515.78,515.78,0,0,1,39.54,47.48c6.69,8.72,13.14,17.78,19.17,26.95,8,12.13,15.47,24.79,22.25,37.63a36,36,0,0,1-63.67,33.62c-5.71-10.81-12-21.47-18.72-31.67-5.17-7.85-10.7-15.61-16.43-23.07-.26-.33-.51-.66-.75-1a446.16,446.16,0,0,0-34.28-41.09c-33-34.8-49.13-38.25-50.86-38.53-1-.16-2.26-.28-2.91-.33-9.36-.38-20.53,4.87-23.57,6.55a33.41,33.41,0,0,0-11.08,12.9,51.21,51.21,0,0,0-3.46,18.84c.45,20.52,22.2,49.68,49.74,86.59,13.6,18.22,29,38.87,44.75,62.36,6.17,9.2,15.48,23.09,25.84,40.68,1.19,2,7.43,12.64,14,25a767.09,767.09,0,0,1,36.83,80.58,36,36,0,0,1-33.5,49.18ZM4211.63,263.62l-.09.19Z"/><path d="M4379.25,773.25c-47.74,0-89.62-7.88-124.86-23.51-39.29-17.43-68.73-44.56-82.89-76.38-17-38.16-10.38-78.4,17.22-105,18.72-18.07,44.91-27.7,75.73-27.86,30.07-.17,63.59,8.68,99.57,26.25a36,36,0,0,1-31.6,64.7c-55.24-27-84.89-19.79-93.71-11.28-7.63,7.36-3.54,19.19-1.43,23.94C4251.89,676.92,4310,707,4407,700.25a36,36,0,0,1,5,71.82Q4395.22,773.24,4379.25,773.25Z"/><path d="M4464.16,902a36,36,0,0,1-33.32-22.34L4378.5,752.12a36,36,0,0,1,66.61-27.34l52.34,127.55A36,36,0,0,1,4464.16,902Z"/>
        </g>
      </g>
    </svg>
    """
  end

  def chat(assigns) do
    ~H"""
    <svg width="81" height="45" viewBox="0 0 81 45" fill="none" xmlns="http://www.w3.org/2000/svg">
    <rect width="81" height="45" rx="15" fill="#FFB81C"/>
    <path d="M21.56 22.4C21.56 25.744 24.008 28.096 27.224 28.096C29.704 28.096 31.72 26.784 32.472 24.48H29.896C29.368 25.568 28.408 26.096 27.208 26.096C25.256 26.096 23.864 24.656 23.864 22.4C23.864 20.128 25.256 18.704 27.208 18.704C28.408 18.704 29.368 19.232 29.896 20.304H32.472C31.72 18.016 29.704 16.688 27.224 16.688C24.008 16.688 21.56 19.056 21.56 22.4ZM34.3853 28H36.6253V23.104C36.6253 21.68 37.4093 20.912 38.6253 20.912C39.8093 20.912 40.5933 21.68 40.5933 23.104V28H42.8333V22.8C42.8333 20.352 41.3773 19.008 39.3773 19.008C38.1933 19.008 37.2013 19.488 36.6253 20.24V16.16H34.3853V28ZM44.3874 23.536C44.3874 26.304 46.1794 28.144 48.4194 28.144C49.8274 28.144 50.8354 27.472 51.3634 26.704V28H53.6194V19.136H51.3634V20.4C50.8354 19.664 49.8594 18.992 48.4354 18.992C46.1794 18.992 44.3874 20.768 44.3874 23.536ZM51.3634 23.568C51.3634 25.248 50.2434 26.176 49.0114 26.176C47.8114 26.176 46.6754 25.216 46.6754 23.536C46.6754 21.856 47.8114 20.96 49.0114 20.96C50.2434 20.96 51.3634 21.888 51.3634 23.568ZM56.1591 25.248C56.1591 27.28 57.2951 28 58.9911 28H60.3991V26.112H59.3591C58.6551 26.112 58.4151 25.856 58.4151 25.264V20.976H60.3991V19.136H58.4151V16.944H56.1591V19.136H55.1031V20.976H56.1591V25.248Z" fill="#404252"/>
    </svg>

    """
  end

  def logo(assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg"
         class={@class}
         viewBox="0 0 1303.31 1303.3">
      <title>Scratchbac Icon</title>
      <g id="Layer_2" data-name="Layer 2">
        <g id="Layer_1-2" data-name="Layer 1">
          <path d="M1251.3,979.13a52,52,0,0,1-48-32.06c-12.88-31-25.71-62.1-38.11-92.21-62.72-152.21-122-296-198.84-449.34-41.77-77.31-84.19-146.85-122.72-201.16-49.77-70.14-72.05-85.36-74.43-86.86-19.23-12.17-36.26-13.35-39-13.46a52.19,52.19,0,0,0-18.49,4.41c-5.91,3.82-9,10.7-10,13-7.28,16.29,2.15,35.44,3.25,37.57a52,52,0,0,1-92.47,47.68c-7.89-15.32-31.64-69.78-5.75-127.7,15.56-34.81,39.18-53.23,56.26-62.56.92-.51,1.87-1,2.83-1.43A155.74,155.74,0,0,1,728.09,0c4.92-.13,49.3-.42,96.69,29.57C888.37,69.83,987.06,225,1058.21,356.78c.25.46.49.92.73,1.39,78.77,157.06,138.81,302.78,202.38,457.06,12.38,30,25.17,61.08,38,91.91a52,52,0,0,1-48,72ZM730.88,104l-.48,0A4.34,4.34,0,0,0,730.88,104Z"/><path d="M738.39,372.69a52,52,0,0,1-48.13-32.25A409,409,0,0,0,669.88,298c-.61-1.07-5.52-9.76-10.8-18.37C591.78,169.77,541.43,137.42,517.4,127.91c-10.2-4-17.17-5.26-24.06-4.22-.17,0-19.95,3.33-29.47,18a41.6,41.6,0,0,0-6.44,15.83c-3.48,21.21,14.28,41.75,16.32,44A52,52,0,0,1,396.28,271c-12.47-13.92-52.32-64.44-41.51-130.31A144.81,144.81,0,0,1,376.63,85c33.51-51.58,90.14-62.5,101.15-64.17,33.55-5.08,60.53,3.47,77.9,10.35,64.11,25.36,128.74,90.67,192.11,194.1,6.66,10.88,12.59,21.42,12.84,21.87.06.09.11.19.16.28a515.14,515.14,0,0,1,25.69,53.45,52,52,0,0,1-48.09,71.81Z"/><path d="M579.31,491.55a52,52,0,0,1-45.47-26.68c-15.43-27.64-32.25-55.11-50-81.63-17.35-25.92-29.88-44.65-48.29-66.89-32.26-39-68.82-83.17-113.67-91.19-6.55-1.17-15.95-2.09-23.59.2-13,3.89-22.42,14.28-26.52,22-9.17,17.21-3.95,43.14,12.67,63.08a52,52,0,1,1-79.88,66.64c-21.05-25.23-34.7-55-39.47-86.05-5-32.84.09-64.85,14.85-92.57,18.36-34.46,51.45-61.66,88.52-72.76,21.88-6.54,46-7.54,71.72-2.94C422.57,137.48,476.39,202.52,515.7,250c21.78,26.32,37,49,54.59,75.35,19.31,28.85,37.61,58.73,54.39,88.81a52,52,0,0,1-45.37,77.37Z"/><path d="M303,905.52a52,52,0,0,1-48.42-33c-15.21-38.68-31.4-74.15-48.13-105.42-8.74-16.33-17.19-30.71-18.13-32.3-13.46-22.83-25.42-40.67-34.15-53.69-21.28-31.76-42.71-60.48-61.61-85.82C41.63,527.05,1.41,473.16,0,410.24c-.83-38,11.91-67.41,14.47-72.92,11.69-25.16,29.67-46.08,53.41-62.17.64-.43,1.3-.86,2-1.26,4.61-2.84,46.46-27.61,94.92-25.13a4.93,4.93,0,0,1,.55,0c1.21.07,7.62.5,14.54,1.62,40.08,6.47,83.69,35.19,133.34,87.79a745.93,745.93,0,0,1,57.13,68.61c9.67,12.59,19,25.69,27.7,38.94,11.53,17.52,22.35,35.82,32.14,54.37a52,52,0,1,1-92,48.58c-8.25-15.62-17.35-31-27-45.76-7.47-11.35-15.45-22.56-23.74-33.33-.37-.48-.73-1-1.08-1.45A643.63,643.63,0,0,0,236.8,408.8c-47.65-50.29-71-55.28-73.48-55.69-1.41-.22-3.26-.4-4.21-.48-13.52-.54-29.66,7.05-34.05,9.48a48.31,48.31,0,0,0-16,18.64,73.87,73.87,0,0,0-5,27.22c.64,29.64,32.08,71.77,71.87,125.11,19.65,26.33,41.92,56.17,64.66,90.11,8.91,13.28,22.36,33.36,37.34,58.77,1.71,2.89,10.72,18.26,20.25,36.07,18.63,34.82,36.53,74,53.21,116.43A52,52,0,0,1,303,905.52ZM109,380.9c0,.09-.09.18-.13.27Z"/><path d="M351.17,1117.26c-69,0-129.49-11.38-180.41-34C114,1058.1,71.46,1018.91,51,972.93,26.47,917.8,36,859.65,75.87,821.18c27.05-26.1,64.89-40,109.43-40.25,43.45-.24,91.88,12.54,143.86,37.94a52,52,0,1,1-45.66,93.47c-79.8-39-122.66-28.58-135.4-16.29-11,10.63-5.1,27.73-2,34.59,21.11,47.44,105.12,90.93,245.23,81.14a52,52,0,1,1,7.25,103.78Q374.25,1117.26,351.17,1117.26Z"/><path d="M473.86,1303.3A52,52,0,0,1,425.72,1271l-75.63-184.29a52,52,0,1,1,96.24-39.5L522,1231.52a52,52,0,0,1-48.1,71.78Z"/>
        </g>
      </g>
    </svg>
    """
  end

  def location(assigns) do
    ~H"""
    <svg class="dark:fill-white" width="14" height="15" viewBox="0 0 14 15" fill="none" xmlns="http://www.w3.org/2000/svg">
    <path d="M7 9C8.24264 9 9.25 7.99264 9.25 6.75C9.25 5.50736 8.24264 4.5 7 4.5C5.75736 4.5 4.75 5.50736 4.75 6.75C4.75 7.99264 5.75736 9 7 9Z" stroke="#404252" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
    <path d="M7 14.25C10.3137 12.75 13 10.0637 13 6.75C13 3.43629 10.3137 0.75 7 0.75C3.68629 0.75 1 3.43629 1 6.75C1 10.0637 3.68629 12.75 7 14.25Z" stroke="#404252" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
    </svg>
    """
  end

  def google(%{type: "social_media"} = assigns) do
    ~H"""
    <svg width="18" height="19" viewBox="0 0 18 19" fill="none" xmlns="http://www.w3.org/2000/svg" class={@class}>
    <rect width="17.3729" height="17.3729" transform="translate(0.624023 0.689453)" fill="#101223"/>
    <path fill-rule="evenodd" clip-rule="evenodd" d="M17.3031 9.56602C17.3031 8.97574 17.2501 8.40816 17.1517 7.86328H9.31152V11.0834H13.7916C13.5986 12.1239 13.0121 13.0056 12.1305 13.5958V15.6845H14.8208C16.3949 14.2353 17.3031 12.1012 17.3031 9.56602Z" fill="#4285F4"/>
    <path fill-rule="evenodd" clip-rule="evenodd" d="M9.31116 17.7009C11.5588 17.7009 13.4432 16.9554 14.8205 15.6841L12.1301 13.5954C11.3847 14.0948 10.4312 14.39 9.31116 14.39C7.143 14.39 5.30783 12.9256 4.65322 10.958H1.87207V13.1148C3.24183 15.8354 6.05703 17.7009 9.31116 17.7009Z" fill="#34A853"/>
    <path fill-rule="evenodd" clip-rule="evenodd" d="M4.6529 10.9588C4.48641 10.4593 4.39181 9.9258 4.39181 9.37714C4.39181 8.82848 4.48641 8.29495 4.6529 7.79548V5.63867H1.87175C1.30796 6.76248 0.986328 8.03386 0.986328 9.37714C0.986328 10.7204 1.30796 11.9918 1.87175 13.1156L4.6529 10.9588Z" fill="#FBBC05"/>
    <path fill-rule="evenodd" clip-rule="evenodd" d="M9.31116 4.36362C10.5334 4.36362 11.6307 4.78363 12.4934 5.60852L14.881 3.22089C13.4394 1.87762 11.555 1.05273 9.31116 1.05273C6.05703 1.05273 3.24183 2.91818 1.87207 5.63879L4.65322 7.79559C5.30783 5.82798 7.143 4.36362 9.31116 4.36362Z" fill="#EA4335"/>
    </svg>
    """
  end

  def apple(%{type: "apple_svg"} = assigns) do
    ~H"""
    <svg width="18" height="19" viewBox="0 0 15 18" fill="none" xmlns="http://www.w3.org/2000/svg" class={@class}>
    <path d="M14.4764 13.4369C14.2265 14.0141 13.9308 14.5454 13.5881 15.0339C13.1211 15.6999 12.7386 16.1608 12.4439 16.4168C11.987 16.837 11.4975 17.0522 10.9733 17.0644C10.597 17.0644 10.1432 16.9573 9.6149 16.7401C9.0849 16.5239 8.59783 16.4168 8.15248 16.4168C7.6854 16.4168 7.18446 16.5239 6.64864 16.7401C6.11201 16.9573 5.67971 17.0705 5.34919 17.0817C4.84651 17.1031 4.34548 16.8818 3.84535 16.4168C3.52615 16.1384 3.12689 15.6611 2.64859 14.985C2.13542 14.2629 1.71352 13.4257 1.38299 12.4711C1.02901 11.4401 0.851562 10.4417 0.851562 9.47508C0.851562 8.36786 1.09081 7.4129 1.57003 6.61264C1.94665 5.96985 2.44769 5.46279 3.07478 5.09056C3.70187 4.71832 4.37944 4.52863 5.10912 4.5165C5.50838 4.5165 6.03196 4.64 6.6826 4.88272C7.33142 5.12625 7.74801 5.24975 7.93066 5.24975C8.06722 5.24975 8.53001 5.10534 9.31456 4.81745C10.0565 4.55046 10.6827 4.43991 11.1956 4.48346C12.5856 4.59564 13.6299 5.14359 14.3244 6.13077C13.0813 6.88402 12.4663 7.93902 12.4786 9.29243C12.4898 10.3466 12.8722 11.2239 13.6238 11.9204C13.9644 12.2437 14.3448 12.4935 14.7681 12.671C14.6763 12.9372 14.5794 13.1921 14.4764 13.4369ZM11.2884 0.89205C11.2884 1.71832 10.9866 2.48981 10.3849 3.20388C9.65875 4.05278 8.78048 4.54332 7.82807 4.46591C7.81593 4.36679 7.8089 4.26246 7.8089 4.15283C7.8089 3.35961 8.15421 2.51071 8.76743 1.81662C9.07358 1.46519 9.46295 1.17298 9.93513 0.939879C10.4063 0.710256 10.8519 0.583269 11.2711 0.561523C11.2833 0.671983 11.2884 0.782449 11.2884 0.892039V0.89205Z" fill="white"/>
    </svg>

    """
  end

  def ally_btn(assigns) do
    ~H"""
    <svg width="81" height="45" viewBox="0 0 81 45" fill="none" xmlns="http://www.w3.org/2000/svg">
    <rect width="76" height="45" rx="15" fill="#00BFB2"/>
    <path d="M24.336 18.224V21.328H21.312V23.28H24.336V26.384H26.448V23.28H29.472V21.328H26.448V18.224H24.336ZM39.4693 28H41.8373L37.8213 16.816H35.2133L31.1973 28H33.5493L34.2853 25.872H38.7333L39.4693 28ZM38.1253 24.08H34.8932L36.5093 19.408L38.1253 24.08ZM43.3384 28H45.5784V16.16H43.3384V28ZM47.7915 28H50.0315V16.16H47.7915V28ZM56.0206 25.328L53.7326 19.136H51.2206L54.7726 27.776L52.8526 32.192H55.2366L60.7246 19.136H58.3406L56.0206 25.328Z" fill="white"/>
    </svg>
    """
  end

  def share_btn(assigns) do
    ~H"""
    <svg width="45" height="45" viewBox="0 0 45 45" fill="none"  xmlns="http://www.w3.org/2000/svg">
    <rect width="45" height="45" rx="15" fill="#F4F4F4"/>
    <path d="M18.6844 20.6578L25.3125 17.3438M25.3156 26.6578L18.6938 23.3469M31 16C31 17.6569 29.6569 19 28 19C26.3431 19 25 17.6569 25 16C25 14.3431 26.3431 13 28 13C29.6569 13 31 14.3431 31 16ZM19 22C19 23.6569 17.6569 25 16 25C14.3431 25 13 23.6569 13 22C13 20.3431 14.3431 19 16 19C17.6569 19 19 20.3431 19 22ZM31 28C31 29.6569 29.6569 31 28 31C26.3431 31 25 29.6569 25 28C25 26.3431 26.3431 25 28 25C29.6569 25 31 26.3431 31 28Z" stroke="#404252" stroke-width="1.5"/>
    </svg>
    """
  end

  def comment_chat(%{type: "comment"} = assigns) do
    ~H"""
    <svg width="18" height="18" viewBox="0 0 18 19" fill="none" xmlns="http://www.w3.org/2000/svg"  class={@class}>
    <path d="M5.44444 7.27776H11.6667M5.44444 10.8333H9.88888M11.9333 15.8111L17 17.5L15.3111 12.4333C15.3111 12.4333 16.1111 11.2778 16.1111 9.05553C16.1111 4.88273 12.7284 1.5 8.55554 1.5C4.38273 1.5 1 4.88273 1 9.05553C1 13.2283 4.38273 16.6111 8.55554 16.6111C10.8531 16.6111 11.9333 15.8111 11.9333 15.8111Z" stroke="#404252" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
    </svg>

    """
  end

  def like_btn(%{type: "like"} = assigns) do
    ~H"""
    <svg width="18" height="18" viewBox="0 0 17 15" fill="none" xmlns="http://www.w3.org/2000/svg"  class={@class}>
    <path d="M2.1095 7.53849L8.5 14L14.8905 7.5385C15.6009 6.8202 16 5.84598 16 4.83016C16 2.71482 14.304 1 12.2119 1C11.2073 1 10.2438 1.40353 9.53336 2.12183L8.5 3.16667L7.46664 2.12183C6.75624 1.40353 5.79273 1 4.78807 1C2.69598 1 1 2.71482 1 4.83016C1 5.84598 1.3991 6.8202 2.1095 7.53849Z" stroke="#404252" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
    </svg>
    """
  end

  def comment_share(%{type: "share"} = assigns) do
    ~H"""
    <svg width="18" height="18" viewBox="0 0 19 19" fill="none" xmlns="http://www.w3.org/2000/svg" class={@class}>
    <path d="M6.3686 8.23235L12.6284 5.10243M12.6314 13.8991L6.37748 10.7721M18 3.83333C18 5.39814 16.7315 6.66667 15.1667 6.66667C13.6019 6.66667 12.3333 5.39814 12.3333 3.83333C12.3333 2.26853 13.6019 1 15.1667 1C16.7315 1 18 2.26853 18 3.83333ZM6.66667 9.5C6.66667 11.0648 5.39814 12.3333 3.83333 12.3333C2.26853 12.3333 1 11.0648 1 9.5C1 7.93519 2.26853 6.66667 3.83333 6.66667C5.39814 6.66667 6.66667 7.93519 6.66667 9.5ZM18 15.1667C18 16.7315 16.7315 18 15.1667 18C13.6019 18 12.3333 16.7315 12.3333 15.1667C12.3333 13.6019 13.6019 12.3333 15.1667 12.3333C16.7315 12.3333 18 13.6019 18 15.1667Z" stroke="#404252" stroke-width="1.5"/>
    </svg>

    """
  end
end
